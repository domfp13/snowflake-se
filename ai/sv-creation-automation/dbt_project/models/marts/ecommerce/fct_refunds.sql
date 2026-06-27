with refunds as (
    select * from {{ ref('stg_refunds') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
)

select
    r.refund_id,
    r.order_id,
    o.customer_id,
    o.region,
    o.segment,
    r.refund_date,
    r.refund_amount
from refunds r
left join orders o on o.order_id = r.order_id
