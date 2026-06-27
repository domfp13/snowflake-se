with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
)

select
    o.order_id,
    o.customer_id,
    c.region,
    c.segment,
    o.order_date,
    o.status,
    o.order_amount,
    o.is_completed
from orders o
left join customers c on c.customer_id = o.customer_id
