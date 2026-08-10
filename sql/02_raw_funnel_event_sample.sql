SELECT
  event_date,

  TIMESTAMP_MICROS(event_timestamp) AS event_time,

  event_name,

  user_pseudo_id,

  (
    SELECT value.int_value
    FROM UNNEST(event_params)
    WHERE key = 'ga_session_id'
  ) AS ga_session_id,

  device.category AS device_category,

  geo.country AS country,

  traffic_source.source AS traffic_source,

  traffic_source.medium AS traffic_medium,

  ecommerce.transaction_id,

  ecommerce.purchase_revenue

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

  AND event_name IN (
    'session_start',
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  )

ORDER BY
  event_timestamp

LIMIT 100;

