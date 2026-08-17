-- Semantic View: Sales Analytics
-- Uses the dbt_semantic_view package materialization to manage the SV lifecycle.
-- Materializations are declared in config and managed declaratively via
-- SYSTEM$MANAGE_SEMANTIC_VIEW_MATERIALIZATIONS_FROM_YAML.

{%- set sv_mats_yaml -%}
materializations:
  - name: revenue_by_region_month
    warehouse: {{ target.warehouse }}
    dimensions:
      - table: customers
        name: region
      - table: orders
        name: order_month
    metrics:
      - table: orders
        name: total_revenue
      - table: orders
        name: total_orders
  - name: revenue_by_segment
    warehouse: {{ target.warehouse }}
    dimensions:
      - table: customers
        name: segment
      - table: orders
        name: order_year
    metrics:
      - table: orders
        name: total_revenue
    immutable_where: "order_year < 2024"
{%- endset -%}

{{ config(
    materialized='semantic_view',
    create_or_alter=true,
    max_staleness='1 hour',
    sv_materializations=sv_mats_yaml
) }}

TABLES (
  orders AS {{ ref('order_summary') }},
  customers AS {{ ref('stg_customers') }} UNIQUE (customer_id)
)

RELATIONSHIPS (
  orders_to_customers AS orders(customer_id) REFERENCES customers
)

DIMENSIONS (
  customers.customer_name AS customer_name
    WITH SYNONYMS ('customer', 'account name', 'client'),

  customers.segment AS segment
    WITH SYNONYMS ('tier', 'customer segment'),

  customers.region AS region
    WITH SYNONYMS ('geo', 'geography'),

  orders.product_name AS product_name
    WITH SYNONYMS ('product', 'item'),

  orders.category AS category
    WITH SYNONYMS ('product category', 'product type'),

  orders.order_date AS order_date
    WITH SYNONYMS ('date', 'transaction date'),

  orders.order_month AS order_month
    WITH SYNONYMS ('month'),

  orders.order_year AS YEAR(order_date)
    WITH SYNONYMS ('year')
)

METRICS (
  orders.total_revenue AS SUM(net_amount)
    WITH SYNONYMS ('revenue', 'sales', 'net sales'),

  orders.total_orders AS COUNT(order_id)
    WITH SYNONYMS ('order count', 'number of orders'),

  orders.total_units AS SUM(quantity)
    WITH SYNONYMS ('units', 'quantity sold'),

  orders.total_discount AS SUM(discount_amount)
    WITH SYNONYMS ('discounts given'),

  orders.avg_order_value AS AVG(net_amount)
    WITH SYNONYMS ('AOV', 'average order'),

  orders.discount_rate AS DIV0(SUM(discount_amount), SUM(net_amount))
    WITH SYNONYMS ('discount rate', 'discount percentage')
)

COMMENT = 'Sales analytics semantic view for e-commerce data. Covers revenue, orders, and product performance across customers and time.'
