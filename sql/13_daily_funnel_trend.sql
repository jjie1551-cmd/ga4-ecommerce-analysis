WITH daily_counts AS (
  SELECT
    session_date,

    COUNT(*) AS total_sessions,

    COUNTIF(reached_view) AS view_sessions,

    COUNTIF(reached_checkout) AS checkout_sessions,

    COUNTIF(reached_purchase) AS purchase_sessions

  FROM
    `ga4-ecommerce-analysis-503306.ga4_analysis.session_funnel`

  GROUP BY
    session_date
)

SELECT
  session_date,

  total_sessions,
  view_sessions,
  checkout_sessions,
  purchase_sessions,

  ROUND(
    100 * SAFE_DIVIDE(
      view_sessions,
      total_sessions
    ),
    2
  ) AS session_to_view_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      checkout_sessions,
      view_sessions
    ),
    2
  ) AS view_to_checkout_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      purchase_sessions,
      checkout_sessions
    ),
    2
  ) AS checkout_to_purchase_rate_pct,

  ROUND(
    100 * SAFE_DIVIDE(
      purchase_sessions,
      total_sessions
    ),
    2
  ) AS overall_purchase_rate_pct,

  ROUND(
    AVG(total_sessions) OVER (
      ORDER BY session_date
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ),
    0
  ) AS total_sessions_7d_avg,

  ROUND(
    100 * SAFE_DIVIDE(
      SUM(purchase_sessions) OVER (
        ORDER BY session_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      ),
      SUM(total_sessions) OVER (
        ORDER BY session_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
      )
    ),
    2
  ) AS overall_purchase_rate_7d_pct

FROM daily_counts

ORDER BY
  session_date;

