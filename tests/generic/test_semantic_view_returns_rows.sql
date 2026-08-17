-- Generic test: Verify a semantic view returns at least one row for given dimensions/metrics.
-- Usage in schema.yml:
--   tests:
--     - test_semantic_view_returns_rows:
--         dimensions: ['customer_name', 'order_date']
--         metrics: ['total_revenue']

{% test test_semantic_view_returns_rows(model, dimensions, metrics) %}

{% set dimensions = dimensions | default([]) %}
{% set metrics = metrics | default([]) %}

WITH source_data AS (
    SELECT * FROM SEMANTIC_VIEW(
        {{ model }}
        {% if dimensions %}DIMENSIONS {{ dimensions | join(', ') }}{% endif %}
        {% if metrics %}METRICS {{ metrics | join(', ') }}{% endif %}
    )
    LIMIT 1
)

SELECT
    'Semantic view query returned zero rows' AS error_message
WHERE NOT EXISTS (
    SELECT 1 FROM source_data
)

{% endtest %}
