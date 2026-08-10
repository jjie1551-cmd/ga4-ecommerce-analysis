SELECT
  COUNT(*) AS row_count,

  COUNT(
    DISTINCT CONCAT(
      session_key,
      '|',
      item_name_key
    )
  ) AS distinct_session_item_count,

  COUNTIF(has_view)
    AS view_session_items,

  COUNTIF(has_cart)
    AS cart_session_items,

  COUNTIF(has_checkout)
    AS checkout_session_items,

  COUNTIF(has_purchase)
    AS purchase_session_items,

  COUNTIF(
    has_purchase
    AND NOT has_view
  ) AS purchase_session_items_without_view,

  COUNTIF(
    has_purchase
    AND NOT has_checkout
  ) AS purchase_session_items_without_checkout,

  COUNTIF(strict_purchase)
    AS strict_purchase_session_items,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(strict_purchase),
      COUNTIF(has_purchase)
    ),
    2
  ) AS strict_purchase_coverage_pct

FROM
  `ga4-ecommerce-analysis-503306.ga4_analysis.session_item_funnel`;

