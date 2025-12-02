{{ config(materialized='table') }}

with date_range as (
    select
        min(order_purchase_ts::date) as min_date,
        max(order_purchase_ts::date) as max_date
    from {{ ref('stg_orders') }}
),

calendar as (
    select
        generate_series(min_date, max_date, interval '1 day')::date as date
    from date_range
)

select
    to_char(date, 'YYYYMMDD')::int as date_key,
    date,
    extract(year from date)::int as year,
    extract(month from date)::int as month,
    extract(day from date)::int as day,
    to_char(date, 'Month') as month_name,
    to_char(date, 'Dy') as day_name,
    extract(dow from date)::int as day_of_week,
    case when extract(dow from date) in (0,6) then true else false end as is_weekend
from calendar
