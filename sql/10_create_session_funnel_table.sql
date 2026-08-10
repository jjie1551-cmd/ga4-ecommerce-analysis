CREATE OR REPLACE TABLE
  `ga4-ecommerce-analysis-503306.ga4_analysis.session_funnel`
AS

WITH base_events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,

    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id,

    event_name,
    event_timestamp,

    device.category AS device_category,
    geo.country AS country,

    traffic_source.source AS traffic_source,
    traffic_source.medium AS traffic_medium

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
      event_date
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS session_date,

    ARRAY_AGG(
      COALESCE(device_category, 'unknown')
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS device_category,

    ARRAY_AGG(
      COALESCE(country, 'unknown')
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS country,

    ARRAY_AGG(
      COALESCE(traffic_source, 'unknown')
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS traffic_source,

    ARRAY_AGG(
      COALESCE(traffic_medium, 'unknown')
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS traffic_medium

  FROM valid_events

  WHERE event_name = 'session_start'

  GROUP BY
    user_pseudo_id,
    ga_session_id
),

first_views AS (
  SELECT
    s.*,

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
    s.session_start_time,
    s.session_date,
    s.device_category,
    s.country,
    s.traffic_source,
    s.traffic_medium
),

first_checkouts AS (
  SELECT
    v.*,

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
    v.session_start_time,
    v.session_date,
    v.device_category,
    v.country,
    v.traffic_source,
    v.traffic_medium,
    v.first_view_time
),

first_purchases AS (
  SELECT
    c.*,

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
    c.session_start_time,
    c.session_date,
    c.device_category,
    c.country,
    c.traffic_source,
    c.traffic_medium,
    c.first_view_time,
    c.first_checkout_time
)

SELECT
  CONCAT(
    user_pseudo_id,
    '-',
    CAST(ga_session_id AS STRING)
  ) AS session_key,

  user_pseudo_id,
  ga_session_id,

  session_date,
  device_category,
  country,
  traffic_source,
  traffic_medium,

  session_start_time,
  first_view_time,
  first_checkout_time,
  first_purchase_time,

  first_view_time IS NOT NULL
    AS reached_view,

  first_checkout_time IS NOT NULL
    AS reached_checkout,

  first_purchase_time IS NOT NULL
    AS reached_purchase

FROM first_purchases;

