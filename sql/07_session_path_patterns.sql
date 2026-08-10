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

path_counts AS (
  SELECT
    has_view_item,
    has_add_to_cart,
    has_begin_checkout,
    has_purchase,

    CONCAT(
      '进入网站',
      IF(has_view_item = 1, ' → 浏览商品', ''),
      IF(has_add_to_cart = 1, ' → 加入购物车', ''),
      IF(has_begin_checkout = 1, ' → 开始结账', ''),
      IF(has_purchase = 1, ' → 完成购买', '')
    ) AS path_pattern,

    COUNT(*) AS session_count

  FROM session_level

  WHERE has_session_start = 1

  GROUP BY
    has_view_item,
    has_add_to_cart,
    has_begin_checkout,
    has_purchase
)

SELECT
  path_pattern,
  has_view_item,
  has_add_to_cart,
  has_begin_checkout,
  has_purchase,
  session_count,

  ROUND(
    100 * SAFE_DIVIDE(
      session_count,
      SUM(session_count) OVER ()
    ),
    2
  ) AS session_share_pct

FROM path_counts

ORDER BY session_count DESC;

