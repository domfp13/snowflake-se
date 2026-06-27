with source as (
    select * from {{ source('raw', 'campaigns') }}
)

select
    campaign_id,
    campaign_name,
    channel,
    budget,
    spend,
    start_date,
    end_date,
    target_region
from source
