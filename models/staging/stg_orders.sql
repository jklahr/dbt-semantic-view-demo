select
    order_id,
    customer_id,
    product_id,
    order_date::date as order_date,
    quantity::integer as quantity,
    unit_price::number(10, 2) as unit_price,
    discount_amount::number(10, 2) as discount_amount,
    (quantity * unit_price) as gross_amount,
    (quantity * unit_price) - discount_amount as net_amount
from {{ source('raw', 'raw_orders') }}
