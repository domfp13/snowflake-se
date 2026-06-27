with events as (
    select * from {{ ref('stg_campaign_events') }}
),

campaigns as (
    select * from {{ ref('stg_campaigns') }}
)

select
    e.event_id,
    e.campaign_id,
    e.customer_id,
    e.event_type,
    e.event_timestamp,
    e.device_type,
    c.campaign_name,
    c.channel,
    c.target_region
from events e
left join campaigns c on c.campaign_id = e.campaign_id
