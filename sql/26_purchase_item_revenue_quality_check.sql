WITH purchase_items AS (
  SELECT
    LOWER(TRIM(item.item_name)) AS item_name_key,
    item.item_name,
    item.item_id,

    item.price,
    item.quantity,
    item.item_revenue,

    ecommerce.transaction_id,

    user_pseudo_id,
    event_timestamp,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  CROSS JOIN
    UNNEST(items) AS item

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name = 'purchase'

    AND item.item_name IS NOT NULL
    AND TRIM(item.item_name) != ''
)

SELECT
  COUNT(*) AS purchase_item_rows,

  COUNT(DISTINCT item_name_key)
    AS purchased_item_names,

  COUNTIF(item_revenue IS NULL)
    AS missing_item_revenue_rows,

  ROUND(
    100 * SAFE_DIVIDE(
      COUNTIF(item_revenue IS NOT NULL),
      COUNT(*)
    ),
    2
  ) AS item_revenue_coverage_pct,

  COUNTIF(price IS NULL)
    AS missing_price_rows,

  COUNTIF(quantity IS NULL)
    AS missing_quantity_rows,

  COUNTIF(
    item_revenue IS NULL
    AND (
      price IS NULL
      OR quantity IS NULL
    )
  ) AS rows_without_any_revenue_method,

  SUM(item_revenue)
    AS recorded_item_revenue,

  SUM(
    CASE
      WHEN item_revenue IS NULL
           AND price IS NOT NULL
           AND quantity IS NOT NULL
        THEN price * quantity
      ELSE 0
    END
  ) AS estimated_revenue_from_price_quantity

FROM purchase_items;

