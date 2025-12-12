{{ config(materialized='view') }}

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::timestamp as shipping_limit_ts,
    price::numeric,
    freight_value::numeric
from {{ source('olist_oltp', 'order_items') }}
