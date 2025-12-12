{{ config(materialized='table') }}

with orders_per_customer as (
    select
        o.customer_id,
        min(o.order_purchase_ts::date) as first_order_date,
        max(o.order_purchase_ts::date) as most_recent_order_date,
        count(distinct o.order_id) as total_orders
    from {{ ref('stg_orders') }} o
    group by o.customer_id
)

select
    row_number() over (order by c.customer_id) as customer_key,
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    o.first_order_date,
    o.most_recent_order_date,
    o.total_orders
from {{ ref('stg_customers') }} c
left join orders_per_customer o
    on c.customer_id = o.customer_id
