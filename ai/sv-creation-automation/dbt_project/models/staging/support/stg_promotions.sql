with source as (
    select * from {{ source('raw', 'promotions') }}
)

select
    promotion_id,
    promo_code,
    discount_type,
    discount_value,
    start_date,
    end_date,
    min_order_amount
from source
