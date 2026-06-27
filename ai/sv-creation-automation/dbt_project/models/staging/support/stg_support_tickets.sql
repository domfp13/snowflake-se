with source as (
    select * from {{ source('raw', 'support_tickets') }}
)

select
    ticket_id,
    customer_id,
    order_id,
    category,
    priority,
    status,
    created_at,
    resolved_at,
    satisfaction_score
from source
