select
    o.order_id,
    o.customer_id,
    o.product_id,
    o.order_date,
    date_trunc('month', o.order_date) as order_month,
    extract(year from o.order_date) as order_year,
    c.customer_name,
    c.segment,
    c.region,
    p.product_name,
    p.category,
    o.quantity,
    o.unit_price,
    o.discount_amount,
    o.gross_amount,
    o.net_amount
from {{ ref('stg_orders') }} o
join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
join {{ ref('stg_products') }} p on o.product_id = p.product_id
