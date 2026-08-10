-- 最终修正版：原版本误读 product_funnel_performance，无法取得第 24 步生成的
-- product_quadrant 和 data_reliability_note；本版改读 product_quadrant_analysis。

SELECT
  item_name,
  item_category,

  view_session_items,
  all_purchase_session_items,
  strict_purchase_session_items,

  strict_view_to_purchase_rate_pct,
  strict_purchase_coverage_pct,

  product_quadrant,
  data_reliability_note,

  RANK() OVER (
    ORDER BY all_purchase_session_items DESC
  ) AS purchase_heat_rank

FROM
  `ga4-ecommerce-analysis-503306.ga4_analysis.product_quadrant_analysis`

ORDER BY
  all_purchase_session_items DESC,
  view_session_items DESC

LIMIT 30;

