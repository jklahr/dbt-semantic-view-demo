select
    product_id,
    product_name,
    category,
    unit_price::number(10, 2) as unit_price
from {{ source('raw', 'raw_products') }}
