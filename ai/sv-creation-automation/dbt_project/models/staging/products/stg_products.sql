with source as (
    select * from {{ source('raw', 'products') }}
)

select
    product_id,
    product_name,
    category_id,
    list_price,
    cost_price,
    created_date,
    is_active
from source
