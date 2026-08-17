select
    customer_id,
    customer_name,
    email,
    segment,
    region,
    created_at::date as created_at
from {{ source('raw', 'raw_customers') }}
