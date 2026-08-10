CREATE OR REPLACE TABLE
  `ga4-ecommerce-analysis-503306.ga4_analysis.session_item_funnel`
AS

WITH item_events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id,

    event_name,
    event_timestamp,

    LOWER(TRIM(item.item_name)) AS item_name_key,
    item.item_name,
    item.item_category

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  CROSS JOIN
    UNNEST(items) AS item

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name IN (
      'view_item',
      'add_to_cart',
      'begin_checkout',
      'purchase'
    )

    AND user_pseudo_id IS NOT NULL

    AND item.item_name IS NOT NULL
    AND TRIM(item.item_name) != ''
),

valid_item_events AS (
  SELECT
    s.session_key,
    s.session_date,
    s.device_category,
    s.country,
    s.traffic_source,
    s.traffic_medium,

    e.user_pseudo_id,
    e.ga_session_id,
    e.event_name,
    e.event_timestamp,
    e.item_name_key,
    e.item_name,
    e.item_category

  FROM item_events e

  INNER JOIN
    `ga4-ecommerce-analysis-503306.ga4_analysis.session_funnel` s

    ON e.user_pseudo_id = s.user_pseudo_id
   AND e.ga_session_id = s.ga_session_id
),

session_item_times AS (
  SELECT
    session_key,
    user_pseudo_id,
    ga_session_id,

    session_date,
    device_category,
    country,
    traffic_source,
    traffic_medium,

    item_name_key,

    ARRAY_AGG(
      item_name
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS item_name,

    ARRAY_AGG(
      item_category
      IGNORE NULLS
      ORDER BY event_timestamp
      LIMIT 1
    )[SAFE_OFFSET(0)] AS item_category,

    MIN(
      IF(event_name = 'view_item', event_timestamp, NULL)
    ) AS first_view_time,

    MIN(
      IF(event_name = 'add_to_cart', event_timestamp, NULL)
    ) AS first_cart_time,

    MIN(
      IF(event_name = 'begin_checkout', event_timestamp, NULL)
    ) AS first_checkout_time,

    MIN(
      IF(event_name = 'purchase', event_timestamp, NULL)
    ) AS first_purchase_time

  FROM valid_item_events

  GROUP BY
    session_key,
    user_pseudo_id,
    ga_session_id,
    session_date,
    device_category,
    country,
    traffic_source,
    traffic_medium,
    item_name_key
)

SELECT
  *,

  first_view_time IS NOT NULL
    AS has_view,

  first_cart_time IS NOT NULL
    AS has_cart,

  first_checkout_time IS NOT NULL
    AS has_checkout,

  first_purchase_time IS NOT NULL
    AS has_purchase,

  IF(
    first_view_time IS NOT NULL
    AND first_cart_time IS NOT NULL
    AND first_cart_time >= first_view_time,
    TRUE,
    FALSE
  ) AS cart_after_view,

  IF(
    first_view_time IS NOT NULL
    AND first_checkout_time IS NOT NULL
    AND first_checkout_time >= first_view_time,
    TRUE,
    FALSE
  ) AS checkout_after_view,

  IF(
    first_view_time IS NOT NULL
    AND first_checkout_time IS NOT NULL
    AND first_purchase_time IS NOT NULL
    AND first_checkout_time >= first_view_time
    AND first_purchase_time >= first_checkout_time,
    TRUE,
    FALSE
  ) AS strict_purchase

FROM session_item_times;

