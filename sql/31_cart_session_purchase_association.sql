WITH cart_by_session AS (
  SELECT
    session_key,

    LOGICAL_OR(has_cart)
      AS has_any_cart,

    COUNTIF(has_cart)
      AS carted_item_count

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.session_item_funnel`

  GROUP BY
    session_key
),

session_cart_analysis AS (
  SELECT
    s.session_key,
    s.reached_purchase,

    COALESCE(
      c.has_any_cart,
      FALSE
    ) AS has_any_cart,

    COALESCE(
      c.carted_item_count,
      0
    ) AS carted_item_count

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.session_funnel` s

  LEFT JOIN cart_by_session c
    USING (session_key)
)

SELECT
  CASE
    WHEN has_any_cart
      THEN '有加购行为'
    ELSE '无加购行为'
  END AS cart_group,

  COUNT(*) AS total_sessions,

  COUNTIF(reached_purchase)
    AS purchase_sessions,

  COUNTIF(NOT reached_purchase)
    AS non_purchase_sessions,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(reached_purchase),
      COUNT(*)
    ),
    2
  ) AS strict_purchase_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNT(*),
      SUM(COUNT(*)) OVER ()
    ),
    2
  ) AS session_share_pct,

  ROUND(
    AVG(carted_item_count),
    2
  ) AS avg_carted_item_count

FROM session_cart_analysis

GROUP BY
  cart_group

ORDER BY
  total_sessions DESC;

