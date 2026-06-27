with promotions as (
    select * from {{ ref('stg_promotions') }}
)

select
    promotion_id,
    promo_code,
    discount_type,
    discount_value,
    start_date,
    end_date,
    min_order_amount,
    CASE
        WHEN current_date() BETWEEN start_date AND end_date THEN 'Active'
        WHEN current_date() < start_date THEN 'Upcoming'
        ELSE 'Expired'
    END as promotion_status
from promotions
