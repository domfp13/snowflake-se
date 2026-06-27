with source as (
    select * from {{ source('raw', 'payments') }}
)

select
    payment_id,
    order_id,
    payment_seq,
    payment_method,
    payment_amount,
    payment_date,
    payment_status
from source
