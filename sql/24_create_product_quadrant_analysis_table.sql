CREATE OR REPLACE TABLE
  `ga4-ecommerce-analysis-503306.ga4_analysis.product_quadrant_analysis`
AS

WITH thresholds AS (
  SELECT
    APPROX_QUANTILES(
      view_session_items,
      4
    )[OFFSET(3)] AS high_view_threshold,

    ANY_VALUE(
      benchmark_strict_purchase_rate_pct
    ) AS purchase_rate_benchmark

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.product_funnel_performance`
)

SELECT
  p.item_name,
  p.item_category,

  p.view_session_items,
  p.cart_after_view_session_items,
  p.checkout_after_view_session_items,
  p.strict_purchase_session_items,
  p.all_purchase_session_items,

  p.view_to_cart_rate_pct,
  p.view_to_checkout_rate_pct,
  p.strict_view_to_purchase_rate_pct,
  p.strict_purchase_coverage_pct,

  t.high_view_threshold,
  t.purchase_rate_benchmark,

  CASE
    WHEN p.view_session_items >= t.high_view_threshold
         AND p.strict_view_to_purchase_rate_pct
             >= t.purchase_rate_benchmark
      THEN '高浏览 + 高转化'

    WHEN p.view_session_items >= t.high_view_threshold
         AND p.strict_view_to_purchase_rate_pct
             < t.purchase_rate_benchmark
      THEN '高浏览 + 低转化'

    WHEN p.view_session_items < t.high_view_threshold
         AND p.strict_view_to_purchase_rate_pct
             >= t.purchase_rate_benchmark
      THEN '低浏览 + 高转化'

    ELSE '低浏览 + 低转化'
  END AS product_quadrant,

  ROUND(
    GREATEST(
      0,
      p.view_session_items
      * (
          t.purchase_rate_benchmark
          - p.strict_view_to_purchase_rate_pct
        )
      / 100
    ),
    1
  ) AS estimated_gap_vs_benchmark,

  CASE
    WHEN p.all_purchase_session_items < 20
      THEN '购买样本较少'

    WHEN p.strict_purchase_coverage_pct IS NULL
         OR p.strict_purchase_coverage_pct < 50
      THEN '严格路径覆盖较低'

    ELSE '可用于初步比较'
  END AS data_reliability_note

FROM
  `ga4-ecommerce-analysis-503306.ga4_analysis.product_funnel_performance` p

CROSS JOIN thresholds t;

