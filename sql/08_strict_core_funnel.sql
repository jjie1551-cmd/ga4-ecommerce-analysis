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

-- 第一步：确定每次会话最早的开始时间
session_starts AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    MIN(event_timestamp) AS session_start_time
  FROM valid_events
  WHERE event_name = 'session_start'
  GROUP BY
    user_pseudo_id,
    ga_session_id
),

-- 第二步：寻找会话开始后第一次浏览商品
first_views AS (
  SELECT
    s.user_pseudo_id,
    s.ga_session_id,
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
    s.session_start_time
),

-- 第三步：寻找浏览商品后第一次开始结账
first_checkouts AS (
  SELECT
    v.user_pseudo_id,
    v.ga_session_id,
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
    v.session_start_time,
    v.first_view_time
),

-- 第四步：寻找开始结账后第一次完成购买
first_purchases AS (
  SELECT
    c.user_pseudo_id,
    c.ga_session_id,
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
    c.session_start_time,
    c.first_view_time,
    c.first_checkout_time
),

funnel_counts AS (
  SELECT
    1 AS stage_order,
    '进入网站' AS funnel_stage,
    COUNT(*) AS session_count
  FROM first_purchases

  UNION ALL

  SELECT
    2,
    '浏览商品',
    COUNTIF(first_view_time IS NOT NULL)
  FROM first_purchases

  UNION ALL

  SELECT
    3,
    '开始结账',
    COUNTIF(first_checkout_time IS NOT NULL)
  FROM first_purchases

  UNION ALL

  SELECT
    4,
    '完成购买',
    COUNTIF(first_purchase_time IS NOT NULL)
  FROM first_purchases
),

funnel_metrics AS (
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
    100 * SAFE_DIVIDE(session_count, starting_sessions),
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

FROM funnel_metrics

ORDER BY stage_order;

