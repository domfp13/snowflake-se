with shipments as (
    select * from {{ ref('fct_shipments') }}
)

select
    region,
    date_trunc('month', shipped_date) as ship_month,
    shipping_method,
    count(*) as shipment_count,
    round(avg(delivery_days), 1) as avg_delivery_days,
    round(sum(shipping_cost), 2) as total_shipping_cost
from shipments
where delivered_date is not null
group by region, ship_month, shipping_method
