WITH base_events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id,

    event_name

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
),

session_level AS (
  SELECT
    user_pseudo_id,
    ga_session_id,

    CONCAT(
      user_pseudo_id,
      '-',
      CAST(ga_session_id AS STRING)
    ) AS session_key,

    MAX(
      IF(event_name = 'session_start', 1, 0)
    ) AS has_session_start,

    MAX(
      IF(event_name = 'view_item', 1, 0)
    ) AS has_view_item,

    MAX(
      IF(event_name = 'add_to_cart', 1, 0)
    ) AS has_add_to_cart,

    MAX(
      IF(event_name = 'begin_checkout', 1, 0)
    ) AS has_begin_checkout,

    MAX(
      IF(event_name = 'purchase', 1, 0)
    ) AS has_purchase,

    COUNTIF(
      event_name = 'view_item'
    ) AS view_item_event_count,

    COUNTIF(
      event_name = 'add_to_cart'
    ) AS add_to_cart_event_count

  FROM base_events

  WHERE
    user_pseudo_id IS NOT NULL
    AND ga_session_id IS NOT NULL

  GROUP BY
    user_pseudo_id,
    ga_session_id
)

SELECT *
FROM session_level
ORDER BY session_key
LIMIT 100;

