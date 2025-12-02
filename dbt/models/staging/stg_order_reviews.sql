{{ config(materialized='view') }}

select
    order_id,
    review_score
from {{ source('olist_oltp', 'order_reviews') }}
