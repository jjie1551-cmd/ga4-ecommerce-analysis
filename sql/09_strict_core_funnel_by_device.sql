WITH base_events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id,

    event_name,
    event_timestamp,
    device.category AS device_category

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name IN (
      'session_start',
      'view_item',
      'begin_checkout',
      'purchase'
    )
),

valid_events AS (
  SELECT *
  FROM base_events
  WHERE
    user_pseudo_id IS NOT NULL
    AND ga_session_id IS NOT NULL
),

session_starts AS (
  SELECT
    user_pseudo_id,
    ga_session_id,

    MIN(event_timestamp) AS session_start_time,

    ARRAY_AGG(
      device_category
      IGNORE NULLS
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS device_category

  FROM valid_events

  WHERE event_name = 'session_start'

  GROUP BY
    user_pseudo_id,
    ga_session_id
),

first_views AS (
  SELECT
    s.user_pseudo_id,
    s.ga_session_id,
    s.device_category,
    s.session_start_time,

    MIN(e.event_timestamp) AS first_view_time

  FROM session_starts s

  LEFT JOIN valid_events e
    ON s.user_pseudo_id = e.user_pseudo_id
   AND s.ga_session_id = e.ga_session_id
   AND e.event_name = 'view_item'
   AND e.event_timestamp >= s.session_start_time

  GROUP BY
    s.user_pseudo_id,
    s.ga_session_id,
    s.device_category,
    s.session_start_time
),

first_checkouts AS (
  SELECT
    v.user_pseudo_id,
    v.ga_session_id,
    v.device_category,
    v.session_start_time,
    v.first_view_time,

    MIN(e.event_timestamp) AS first_checkout_time

  FROM first_views v

  LEFT JOIN valid_events e
    ON v.user_pseudo_id = e.user_pseudo_id
   AND v.ga_session_id = e.ga_session_id
   AND e.event_name = 'begin_checkout'
   AND v.first_view_time IS NOT NULL
   AND e.event_timestamp >= v.first_view_time

  GROUP BY
    v.user_pseudo_id,
    v.ga_session_id,
    v.device_category,
    v.session_start_time,
    v.first_view_time
),

first_purchases AS (
  SELECT
    c.user_pseudo_id,
    c.ga_session_id,
    c.device_category,
    c.session_start_time,
    c.first_view_time,
    c.first_checkout_time,

    MIN(e.event_timestamp) AS first_purchase_time

  FROM first_checkouts c

  LEFT JOIN valid_events e
    ON c.user_pseudo_id = e.user_pseudo_id
   AND c.ga_session_id = e.ga_session_id
   AND e.event_name = 'purchase'
   AND c.first_checkout_time IS NOT NULL
   AND e.event_timestamp >= c.first_checkout_time

  GROUP BY
    c.user_pseudo_id,
    c.ga_session_id,
    c.device_category,
    c.session_start_time,
    c.first_view_time,
    c.first_checkout_time
)

SELECT
  COALESCE(device_category, 'unknown') AS device_category,

  COUNT(*) AS total_sessions,

  COUNTIF(first_view_time IS NOT NULL)
    AS view_sessions,

  COUNTIF(first_checkout_time IS NOT NULL)
    AS checkout_sessions,

  COUNTIF(first_purchase_time IS NOT NULL)
    AS purchase_sessions,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(first_view_time IS NOT NULL),
      COUNT(*)
    ),
    2
  ) AS session_to_view_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(first_checkout_time IS NOT NULL),
      COUNTIF(first_view_time IS NOT NULL)
    ),
    2
  ) AS view_to_checkout_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(first_purchase_time IS NOT NULL),
      COUNTIF(first_checkout_time IS NOT NULL)
    ),
    2
  ) AS checkout_to_purchase_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(first_purchase_time IS NOT NULL),
      COUNT(*)
    ),
    2
  ) AS overall_purchase_rate_pct

FROM first_purchases

GROUP BY
  device_category

ORDER BY
  total_sessions DESC;

