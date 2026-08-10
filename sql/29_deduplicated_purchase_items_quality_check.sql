SELECT
  COUNT(*) AS purchase_item_rows,

  COUNT(DISTINCT transaction_id)
    AS distinct_transactions,

  COUNT(DISTINCT item_name_key)
    AS distinct_item_names,

  COUNTIF(item_revenue IS NULL)
    AS missing_item_revenue_rows,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(item_revenue IS NOT NULL),
      COUNT(*)
    ),
    2
  ) AS item_revenue_coverage_pct,

  SUM(item_revenue)
    AS deduplicated_recorded_item_revenue

FROM
  `ga4-ecommerce-analysis-503306.ga4_analysis.deduplicated_purchase_items`;

