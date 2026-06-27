with source as (
    select * from {{ source('raw', 'shipments') }}
)

select
    shipment_id,
    order_id,
    shipped_date,
    delivered_date,
    shipping_method,
    carrier,
    shipping_cost
from source
