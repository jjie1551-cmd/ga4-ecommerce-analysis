WITH base_events AS (
  SELECT
    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id,

    event_name,
    event_timestamp

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

session_times AS (
  SELECT
    user_pseudo_id,
    ga_session_id,

    MIN(
      IF(event_name = 'session_start', event_timestamp, NULL)
    ) AS session_start_time,

    MIN(
      IF(event_name = 'view_item', event_timestamp, NULL)
    ) AS view_item_time,

    MIN(
      IF(event_name = 'add_to_cart', event_timestamp, NULL)
    ) AS add_to_cart_time,

    MIN(
      IF(event_name = 'begin_checkout', event_timestamp, NULL)
    ) AS begin_checkout_time,

    MIN(
      IF(event_name = 'purchase', event_timestamp, NULL)
    ) AS purchase_time

  FROM base_events

  WHERE
    user_pseudo_id IS NOT NULL
    AND ga_session_id IS NOT NULL

  GROUP BY
    user_pseudo_id,
    ga_session_id
),

eligible_sessions AS (
  SELECT *
  FROM session_times
  WHERE session_start_time IS NOT NULL
)

SELECT
  COUNT(*) AS total_sessions,

  COUNTIF(
    add_to_cart_time IS NOT NULL
    AND view_item_time IS NULL
  ) AS cart_without_view,

  COUNTIF(
    begin_checkout_time IS NOT NULL
    AND add_to_cart_time IS NULL
  ) AS checkout_without_cart,

  COUNTIF(
    purchase_time IS NOT NULL
    AND begin_checkout_time IS NULL
  ) AS purchase_without_checkout,

  COUNTIF(
    view_item_time IS NOT NULL
    AND view_item_time < session_start_time
  ) AS view_before_session_start,

  COUNTIF(
    add_to_cart_time IS NOT NULL
    AND view_item_time IS NOT NULL
    AND add_to_cart_time < view_item_time
  ) AS cart_before_view,

  COUNTIF(
    begin_checkout_time IS NOT NULL
    AND add_to_cart_time IS NOT NULL
    AND begin_checkout_time < add_to_cart_time
  ) AS checkout_before_cart,

  COUNTIF(
    purchase_time IS NOT NULL
    AND begin_checkout_time IS NOT NULL
    AND purchase_time < begin_checkout_time
  ) AS purchase_before_checkout,

  COUNTIF(
    purchase_time IS NOT NULL
    AND (
      view_item_time IS NULL
      OR add_to_cart_time IS NULL
      OR begin_checkout_time IS NULL
    )
  ) AS purchase_missing_prior_stage

FROM eligible_sessions;

