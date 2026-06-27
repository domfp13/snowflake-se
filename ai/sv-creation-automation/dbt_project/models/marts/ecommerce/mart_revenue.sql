/*
    MART_REVENUE - Governed revenue metric aggregated by region and month.

    IMPORTANT: This is the model that changes during demo beat #2.
    Initially shows GROSS revenue. The demo branch swaps to NET revenue
    (gross minus refunds) to prove the agent picks up governed metric changes.
*/

with completed_orders as (
    select
        region,
        date_trunc('month', order_date) as revenue_month,
        order_amount
    from {{ ref('fct_orders') }}
    where is_completed = true
)

select
    region,
    revenue_month,
    count(*) as order_count,
    sum(order_amount) as revenue
from completed_orders
group by region, revenue_month
