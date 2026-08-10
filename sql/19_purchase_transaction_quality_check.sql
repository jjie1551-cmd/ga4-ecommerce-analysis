SELECT
  COUNT(*) AS purchase_event_count,

  COUNTIF(
    ecommerce.transaction_id IS NULL
    OR ecommerce.transaction_id = ''
    OR ecommerce.transaction_id = '(not set)'
  ) AS missing_or_invalid_transaction_id_events,

  COUNT(
    DISTINCT IF(
      ecommerce.transaction_id IS NOT NULL
      AND ecommerce.transaction_id != ''
      AND ecommerce.transaction_id != '(not set)',
      ecommerce.transaction_id,
      NULL
    )
  ) AS valid_distinct_transaction_ids,

  COUNTIF(
    ecommerce.purchase_revenue IS NULL
  ) AS missing_purchase_revenue_events,

  SUM(
    ecommerce.purchase_revenue
  ) AS total_purchase_revenue

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

  AND event_name = 'purchase';

