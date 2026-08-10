WITH product_revenue AS (
  SELECT
    item_name_key,

    ANY_VALUE(item_name)
      AS item_name,

    ANY_VALUE(item_category)
      AS item_category,

    COUNT(DISTINCT transaction_id)
      AS purchase_transaction_count,

    COUNT(*) AS purchase_item_rows,

    SUM(quantity)
      AS recorded_quantity,

    COUNTIF(item_revenue IS NOT NULL)
      AS rows_with_revenue,

    ROUND(
      100 * SAFE_DIVIDE(
        COUNTIF(item_revenue IS NOT NULL),
        COUNT(*)
      ),
      2
    ) AS item_revenue_coverage_pct,

    SUM(item_revenue)
      AS recorded_item_revenue

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.deduplicated_purchase_items`

  GROUP BY
    item_name_key
)

SELECT
  r.item_name,
  r.item_category,

  r.purchase_transaction_count,
  r.purchase_item_rows,
  r.recorded_quantity,

  r.item_revenue_coverage_pct,
  r.recorded_item_revenue,

  ROUND(
    SAFE_DIVIDE(
      r.recorded_item_revenue,
      r.purchase_transaction_count
    ),
    2
  ) AS recorded_revenue_per_transaction,

  q.product_quadrant,
  q.strict_view_to_purchase_rate_pct,
  q.data_reliability_note,

  RANK() OVER (
    ORDER BY r.recorded_item_revenue DESC
  ) AS recorded_revenue_rank

FROM product_revenue r

LEFT JOIN
  `ga4-ecommerce-analysis-503306.ga4_analysis.product_quadrant_analysis` q

  ON r.item_name_key = LOWER(TRIM(q.item_name))

WHERE
  r.purchase_transaction_count >= 10

ORDER BY
  r.recorded_item_revenue DESC

LIMIT 30;

