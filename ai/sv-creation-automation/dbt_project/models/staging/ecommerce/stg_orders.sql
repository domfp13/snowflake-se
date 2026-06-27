with source as (
    select * from {{ source('raw', 'orders') }}
)

select
    order_id,
    customer_id,
    order_date,
    status,
    amount as order_amount,
    (status = 'COMPLETED') as is_completed
from source
