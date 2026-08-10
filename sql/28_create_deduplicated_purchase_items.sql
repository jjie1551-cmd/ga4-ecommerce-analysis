CREATE OR REPLACE TABLE
  `ga4-ecommerce-analysis-503306.ga4_analysis.deduplicated_purchase_items`
AS

WITH purchase_events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,

    ecommerce.transaction_id,
    ecommerce.purchase_revenue,

    items,

    ROW_NUMBER() OVER (
      PARTITION BY ecommerce.transaction_id
      ORDER BY event_timestamp
    ) AS event_rank

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name = 'purchase'

    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.transaction_id != ''
    AND ecommerce.transaction_id != '(not set)'
),

deduplicated_events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    transaction_id,
    purchase_revenue,
    items

  FROM purchase_events

  WHERE event_rank = 1
)

SELECT
  transaction_id,
  user_pseudo_id,

  TIMESTAMP_MICROS(event_timestamp)
    AS purchase_time,

  purchase_revenue,

  LOWER(TRIM(item.item_name))
    AS item_name_key,

  item.item_name,
  item.item_id,
  item.item_category,

  item.price,
  item.quantity,
  item.item_revenue

FROM deduplicated_events

CROSS JOIN
  UNNEST(items) AS item

WHERE
  item.item_name IS NOT NULL
  AND TRIM(item.item_name) != '';

