WITH product_cart_metrics AS (
  SELECT
    item_name_key,

    ANY_VALUE(item_name)
      AS item_name,

    ANY_VALUE(item_category)
      AS item_category,

    COUNTIF(cart_after_view)
      AS cart_after_view_sessions,

    COUNTIF(
      cart_after_view
      AND first_purchase_time IS NOT NULL
      AND first_purchase_time >= first_cart_time
    ) AS purchase_after_cart_sessions

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.session_item_funnel`

  GROUP BY
    item_name_key
)

SELECT
  item_name,
  item_category,

  cart_after_view_sessions,
  purchase_after_cart_sessions,

  cart_after_view_sessions
    - purchase_after_cart_sessions
    AS cart_without_purchase_sessions,

  ROUND(
    100 * SAFE_DIVIDE(
      purchase_after_cart_sessions,
      cart_after_view_sessions
    ),
    2
  ) AS cart_to_purchase_rate_pct,

  ROUND(
    100 * (
      1 - SAFE_DIVIDE(
        purchase_after_cart_sessions,
        cart_after_view_sessions
      )
    ),
    2
  ) AS cart_abandonment_rate_pct

FROM product_cart_metrics

WHERE
  cart_after_view_sessions >= 100

ORDER BY
  cart_without_purchase_sessions DESC,
  cart_after_view_sessions DESC;

