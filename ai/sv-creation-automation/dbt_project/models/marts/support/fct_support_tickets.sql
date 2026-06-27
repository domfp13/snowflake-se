with tickets as (
    select * from {{ ref('stg_support_tickets') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
)

select
    t.ticket_id,
    t.customer_id,
    t.order_id,
    t.category,
    t.priority,
    t.status,
    t.created_at,
    t.resolved_at,
    t.satisfaction_score,
    c.region,
    c.segment,
    CASE
        WHEN t.resolved_at IS NOT NULL
        THEN DATEDIFF(hour, t.created_at, t.resolved_at)
        ELSE NULL
    END as resolution_hours
from tickets t
left join customers c on c.customer_id = t.customer_id
