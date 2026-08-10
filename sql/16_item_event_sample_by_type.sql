-- 最终版本：按事件类型各抽取 20 行，替代此前仅按时间取 100 行的临时样本。

WITH item_records AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,

    TIMESTAMP_MICROS(event_timestamp) AS event_time,

    event_name,

    user_pseudo_id,

    (
      SELECT value.int_value
      FROM UNNEST(event_params)
      WHERE key = 'ga_session_id'
    ) AS ga_session_id,

    item.item_id,
    item.item_name,
    item.item_brand,
    item.item_category,
    item.price,
    item.quantity,
    item.item_revenue,

    ecommerce.transaction_id,

    ROW_NUMBER() OVER (
      PARTITION BY event_name
      ORDER BY event_timestamp, item.item_id
    ) AS row_num

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
)

SELECT
  event_date,
  event_time,
  event_name,
  user_pseudo_id,
  ga_session_id,
  item_id,
  item_name,
  item_brand,
  item_category,
  price,
  quantity,
  item_revenue,
  transaction_id

FROM item_records

WHERE row_num <= 20

ORDER BY
  event_name,
  event_time,
  item_id;

