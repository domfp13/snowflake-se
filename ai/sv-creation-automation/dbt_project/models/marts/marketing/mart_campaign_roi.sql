with campaigns as (
    select * from {{ ref('stg_campaigns') }}
),

events as (
    select * from {{ ref('fct_campaign_events') }}
)

select
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.target_region,
    c.budget,
    c.spend,
    count(case when e.event_type = 'impression' then 1 end) as impressions,
    count(case when e.event_type = 'click' then 1 end) as clicks,
    count(case when e.event_type = 'conversion' then 1 end) as conversions,
    case
        when count(case when e.event_type = 'impression' then 1 end) > 0
        then round(count(case when e.event_type = 'click' then 1 end)::float /
                   count(case when e.event_type = 'impression' then 1 end) * 100, 2)
        else 0
    end as click_through_rate,
    case
        when c.spend > 0
        then round(count(case when e.event_type = 'conversion' then 1 end)::float / c.spend * 1000, 2)
        else 0
    end as conversions_per_1k_spend
from campaigns c
left join events e on e.campaign_id = c.campaign_id
group by c.campaign_id, c.campaign_name, c.channel, c.target_region, c.budget, c.spend
