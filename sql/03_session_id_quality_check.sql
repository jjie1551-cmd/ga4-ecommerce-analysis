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
)

SELECT
  COUNT(*) AS funnel_event_rows,

  COUNTIF(user_pseudo_id IS NULL)
    AS missing_user_id_rows,

  COUNTIF(ga_session_id IS NULL)
    AS missing_session_id_rows,

  SAFE_DIVIDE(
    COUNTIF(ga_session_id IS NULL),
    COUNT(*)
  ) AS missing_session_id_rate,

  COUNT(
    DISTINCT IF(
      user_pseudo_id IS NOT NULL
      AND ga_session_id IS NOT NULL,

      CONCAT(
        user_pseudo_id,
        '-',
        CAST(ga_session_id AS STRING)
      ),

      NULL
    )
  ) AS valid_session_count

FROM base_events;

