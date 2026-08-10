WITH item_metrics AS (
  SELECT
    item_name_key,

    ANY_VALUE(item_name) AS item_name,
    ANY_VALUE(item_category) AS item_category,

    COUNTIF(has_view)
      AS view_session_items,

    COUNTIF(cart_after_view)
      AS cart_after_view_session_items,

    COUNTIF(checkout_after_view)
      AS checkout_after_view_session_items,

    COUNTIF(strict_purchase)
      AS strict_purchase_session_items,

    COUNTIF(has_purchase)
      AS all_purchase_session_items

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.session_item_funnel`

  GROUP BY
    item_name_key
),

overall_benchmark AS (
  SELECT
    SUM(view_session_items)
      AS all_view_session_items,

    SAFE_DIVIDE(
      SUM(cart_after_view_session_items),
      SUM(view_session_items)
    ) AS overall_view_to_cart_rate,

    SAFE_DIVIDE(
      SUM(checkout_after_view_session_items),
      SUM(view_session_items)
    ) AS overall_view_to_checkout_rate,

    SAFE_DIVIDE(
      SUM(strict_purchase_session_items),
      SUM(view_session_items)
    ) AS overall_strict_purchase_rate

  FROM item_metrics
)

SELECT
  m.item_name_key,
  m.item_name,
  m.item_category,

  m.view_session_items,
  m.cart_after_view_session_items,
  m.checkout_after_view_session_items,
  m.strict_purchase_session_items,
  m.all_purchase_session_items,

  ROUND(
    100 * SAFE_DIVIDE(
      m.view_session_items,
      b.all_view_session_items
    ),
    2
  ) AS view_share_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      m.cart_after_view_session_items,
      m.view_session_items
    ),
    2
  ) AS view_to_cart_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      m.checkout_after_view_session_items,
      m.view_session_items
    ),
    2
  ) AS view_to_checkout_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      m.strict_purchase_session_items,
      m.view_session_items
    ),
    2
  ) AS strict_view_to_purchase_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      m.strict_purchase_session_items,
      m.checkout_after_view_session_items
    ),
    2
  ) AS strict_checkout_to_purchase_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      m.strict_purchase_session_items,
      m.all_purchase_session_items
    ),
    2
  ) AS strict_purchase_coverage_pct,

  ROUND(
    100 * b.overall_view_to_cart_rate,
    2
  ) AS benchmark_view_to_cart_rate_pct,

  ROUND(
    100 * b.overall_view_to_checkout_rate,
    2
  ) AS benchmark_view_to_checkout_rate_pct,

  ROUND(
    100 * b.overall_strict_purchase_rate,
    2
  ) AS benchmark_strict_purchase_rate_pct

FROM item_metrics m

CROSS JOIN overall_benchmark b

WHERE
  m.view_session_items >= 1000

ORDER BY
  m.view_session_items DESC;

