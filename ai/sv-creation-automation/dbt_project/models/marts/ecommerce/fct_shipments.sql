with shipments as (
    select * from {{ ref('stg_shipments') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
)

select
    s.shipment_id,
    s.order_id,
    s.shipped_date,
    s.delivered_date,
    s.shipping_method,
    s.carrier,
    s.shipping_cost,
    DATEDIFF(day, s.shipped_date, s.delivered_date) as delivery_days,
    o.customer_id,
    o.region,
    o.segment
from shipments s
left join orders o on o.order_id = s.order_id
