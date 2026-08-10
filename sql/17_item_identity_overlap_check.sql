WITH item_events AS (
  SELECT
    event_name,
    item.item_id,
    item.item_name

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

    AND item.item_id IS NOT NULL
    AND item.item_id != ''
),

item_presence AS (
  SELECT
    item_id,

    ARRAY_AGG(
      item_name
      IGNORE NULLS
      LIMIT 1
    )[SAFE_OFFSET(0)] AS sample_item_name,

    COUNT(DISTINCT item_name)
      AS item_name_count,

    LOGICAL_OR(event_name = 'view_item')
      AS appeared_in_view,

    LOGICAL_OR(event_name = 'add_to_cart')
      AS appeared_in_cart,

    LOGICAL_OR(event_name = 'begin_checkout')
      AS appeared_in_checkout,

    LOGICAL_OR(event_name = 'purchase')
      AS appeared_in_purchase

  FROM item_events

  GROUP BY item_id
)

SELECT
  COUNT(*) AS total_distinct_item_ids,

  COUNTIF(item_name_count > 1)
    AS item_ids_with_multiple_names,

  COUNTIF(appeared_in_view)
    AS view_item_ids,

  COUNTIF(appeared_in_cart)
    AS cart_item_ids,

  COUNTIF(appeared_in_checkout)
    AS checkout_item_ids,

  COUNTIF(appeared_in_purchase)
    AS purchase_item_ids,

  COUNTIF(
    appeared_in_purchase
    AND NOT appeared_in_view
  ) AS purchased_item_ids_without_view,

  COUNTIF(
    appeared_in_purchase
    AND NOT appeared_in_cart
  ) AS purchased_item_ids_without_cart,

  COUNTIF(
    appeared_in_purchase
    AND NOT appeared_in_checkout
  ) AS purchased_item_ids_without_checkout

FROM item_presence;

