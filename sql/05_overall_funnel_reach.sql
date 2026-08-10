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

    MAX(IF(event_name = 'session_start', 1, 0))
      AS has_session_start,

    MAX(IF(event_name = 'view_item', 1, 0))
      AS has_view_item,

    MAX(IF(event_name = 'add_to_cart', 1, 0))
      AS has_add_to_cart,

    MAX(IF(event_name = 'begin_checkout', 1, 0))
      AS has_begin_checkout,

    MAX(IF(event_name = 'purchase', 1, 0))
      AS has_purchase

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
  FROM session_level
  WHERE has_session_start = 1
),

funnel_counts AS (
  SELECT
    1 AS stage_order,
    '进入网站' AS funnel_stage,
    COUNT(*) AS session_count
  FROM eligible_sessions

  UNION ALL

  SELECT
    2,
    '浏览商品',
    COUNTIF(has_view_item = 1)
  FROM eligible_sessions

  UNION ALL

  SELECT
    3,
    '加入购物车',
    COUNTIF(has_add_to_cart = 1)
  FROM eligible_sessions

  UNION ALL

  SELECT
    4,
    '开始结账',
    COUNTIF(has_begin_checkout = 1)
  FROM eligible_sessions

  UNION ALL

  SELECT
    5,
    '完成购买',
    COUNTIF(has_purchase = 1)
  FROM eligible_sessions
),

funnel_with_previous AS (
  SELECT
    *,
    FIRST_VALUE(session_count)
      OVER (ORDER BY stage_order) AS starting_sessions,

    LAG(session_count)
      OVER (ORDER BY stage_order) AS previous_stage_sessions

  FROM funnel_counts
)

SELECT
  stage_order,
  funnel_stage,
  session_count,

  ROUND(
    100 * SAFE_DIVIDE(
      session_count,
      starting_sessions
    ),
    2
  ) AS overall_conversion_rate_pct,

  CASE
    WHEN stage_order = 1 THEN NULL
    ELSE ROUND(
      100 * SAFE_DIVIDE(
        session_count,
        previous_stage_sessions
      ),
      2
    )
  END AS step_conversion_rate_pct,

  CASE
    WHEN stage_order = 1 THEN NULL
    ELSE ROUND(
      100 * (
        1 - SAFE_DIVIDE(
          session_count,
          previous_stage_sessions
        )
      ),
      2
    )
  END AS step_dropoff_rate_pct,

  CASE
    WHEN stage_order = 1 THEN NULL
    ELSE previous_stage_sessions - session_count
  END AS lost_sessions

FROM funnel_with_previous

ORDER BY stage_order;

