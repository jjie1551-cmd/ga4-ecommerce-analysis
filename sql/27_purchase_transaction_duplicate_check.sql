WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,

    ecommerce.transaction_id,
    ecommerce.purchase_revenue

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name = 'purchase'
),

valid_transactions AS (
  SELECT *
  FROM purchase_events

  WHERE
    transaction_id IS NOT NULL
    AND transaction_id != ''
    AND transaction_id != '(not set)'
),

transaction_summary AS (
  SELECT
    transaction_id,

    COUNT(*) AS purchase_event_count,

    COUNT(
      DISTINCT purchase_revenue
    ) AS distinct_revenue_count,

    MAX(purchase_revenue)
      AS representative_purchase_revenue

  FROM valid_transactions

  GROUP BY
    transaction_id
)

SELECT
  (
    SELECT COUNT(*)
    FROM purchase_events
  ) AS all_purchase_events,

  (
    SELECT COUNT(*)
    FROM valid_transactions
  ) AS valid_transaction_events,

  COUNT(*) AS valid_distinct_transactions,

  (
    SELECT COUNT(*)
    FROM valid_transactions
  ) - COUNT(*) AS extra_repeated_events,

  COUNTIF(
    purchase_event_count > 1
  ) AS transaction_ids_with_multiple_events,

  MAX(
    purchase_event_count
  ) AS maximum_events_for_one_transaction,

  COUNTIF(
    distinct_revenue_count > 1
  ) AS transaction_ids_with_inconsistent_revenue,

  (
    SELECT SUM(purchase_revenue)
    FROM valid_transactions
  ) AS raw_valid_event_revenue,

  SUM(
    representative_purchase_revenue
  ) AS deduplicated_valid_transaction_revenue

FROM transaction_summary;

