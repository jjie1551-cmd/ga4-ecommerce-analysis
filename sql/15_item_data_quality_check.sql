SELECT
  event_name,

  COUNT(*) AS item_event_rows,

  COUNT(
    DISTINCT COALESCE(
      NULLIF(item.item_id, ''),
      CONCAT('name:', item.item_name)
    )
  ) AS distinct_item_keys,

  COUNTIF(
    item.item_id IS NULL
    OR item.item_id = ''
  ) AS missing_item_id_rows,

  COUNTIF(
    item.item_name IS NULL
    OR item.item_name = ''
  ) AS missing_item_name_rows,

  COUNTIF(
    item.price IS NULL
  ) AS missing_price_rows,

  COUNTIF(
    item.quantity IS NULL
  ) AS missing_quantity_rows

FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

CROSS JOIN
  UNNEST(items) AS item

WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

  AND event_name IN (
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'purchase'
  )

GROUP BY
  event_name

ORDER BY
  item_event_rows DESC;

