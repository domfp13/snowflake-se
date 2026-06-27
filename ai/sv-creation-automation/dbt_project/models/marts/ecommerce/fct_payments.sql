with payments as (
    select * from {{ ref('stg_payments') }}
),

orders as (
    select * from {{ ref('fct_orders') }}
)

select
    p.payment_id,
    p.order_id,
    p.payment_seq,
    p.payment_method,
    p.payment_amount,
    p.payment_date,
    p.payment_status,
    o.customer_id,
    o.region,
    o.segment
from payments p
left join orders o on o.order_id = p.order_id
