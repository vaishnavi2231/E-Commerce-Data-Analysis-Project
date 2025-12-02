{{ config(materialized='table') }}

with base as (
    select
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        oi.price::numeric,
        oi.freight_value::numeric,
        (oi.price::numeric + oi.freight_value::numeric) as item_revenue,
        o.customer_id,
        o.order_purchase_ts::date as order_date,
        o.delivered_ts::date as delivered_date,
        o.estimated_delivery_ts::date as estimated_delivery_date,
        r.review_score
    from {{ ref('stg_order_items') }} oi
    join {{ ref('stg_orders') }} o
        on oi.order_id = o.order_id
    left join {{ ref('stg_order_reviews') }} r
        on o.order_id = r.order_id
),

linked_keys as (
    select
        b.*,
        c.customer_key,
        s.seller_key,
        pr.product_key,
        od.date_key  as order_date_key,
        dd.date_key  as delivery_date_key,
        pd.date_key  as estimated_delivery_date_key,
        case
            when delivered_date is not null
             and estimated_delivery_date is not null
             and delivered_date > estimated_delivery_date
            then true
            else false
        end as is_late_delivery
    from base b
    left join {{ ref('dim_customer') }} c
        on b.customer_id = c.customer_id
    left join {{ ref('dim_seller') }} s
        on b.seller_id = s.seller_id
    left join {{ ref('dim_product') }} pr
        on b.product_id = pr.product_id
    left join {{ ref('dim_date') }} od
        on b.order_date = od.date
    left join {{ ref('dim_date') }} dd
        on b.delivered_date = dd.date
    left join {{ ref('dim_date') }} pd
        on b.estimated_delivery_date = pd.date
)

select
    row_number() over (order by order_id, order_item_id) as order_item_key,
    order_id,
    order_item_id,
    customer_key,
    seller_key,
    product_key,
    order_date_key,
    delivery_date_key,
    estimated_delivery_date_key,
    price,
    freight_value,
    item_revenue,
    review_score,
    is_late_delivery
from linked_keys
