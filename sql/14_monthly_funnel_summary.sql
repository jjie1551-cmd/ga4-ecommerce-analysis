SELECT
  FORMAT_DATE('%Y-%m', session_date) AS month,

  COUNT(*) AS total_sessions,
  COUNTIF(reached_view) AS view_sessions,
  COUNTIF(reached_checkout) AS checkout_sessions,
  COUNTIF(reached_purchase) AS purchase_sessions,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(reached_view),
      COUNT(*)
    ),
    2
  ) AS session_to_view_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(reached_checkout),
      COUNTIF(reached_view)
    ),
    2
  ) AS view_to_checkout_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(reached_purchase),
      COUNTIF(reached_checkout)
    ),
    2
  ) AS checkout_to_purchase_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(reached_purchase),
      COUNT(*)
    ),
    2
  ) AS overall_purchase_rate_pct

FROM
  `ga4-ecommerce-analysis-503306.ga4_analysis.session_funnel`

GROUP BY
  month

ORDER BY
  month;

