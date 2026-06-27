with source as (
    select * from {{ source('raw', 'campaign_events') }}
)

select
    event_id,
    campaign_id,
    customer_id,
    event_type,
    event_timestamp,
    device_type
from source
