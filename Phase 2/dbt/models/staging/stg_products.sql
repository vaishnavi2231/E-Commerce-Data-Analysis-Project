{{ config(materialized='view') }}

select
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
from {{ source('olist_oltp', 'products') }} p
left join {{ source('olist_oltp', 'product_category_translation') }} t
    on p.product_category_name = t.product_category_name