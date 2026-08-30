-- =============================================================================
-- CREATE AGENT: Sales Analytics Agent
-- Wraps the semantic view for natural language querying.
-- Run this AFTER the dbt pipeline has created the semantic view.
-- =============================================================================

CREATE OR REPLACE AGENT SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_AGENT
  COMMENT = 'E-commerce analytics agent powered by the sales_analytics_sv semantic view.'
  PROFILE = '{"display_name": "Sales Analytics"}'
  FROM SPECIFICATION $$
{
  "models": { "orchestration": "auto" },
  "instructions": {
    "orchestration": "You are the Sales Analytics Agent for an e-commerce business.\n\nCRITICAL: ALWAYS call the query_sales_data tool to answer ANY question. NEVER ask clarifying questions. NEVER say you need more context. The semantic view contains ALL the data you need — all orders, all customers, all products, all time periods.\n\nIf the user asks about revenue, orders, customers, products, discounts, or any business metric — immediately call query_sales_data with their question. Do not ask what time period, what data source, or what scope.",
    "response": "Lead with the direct answer — state the number or insight immediately. Use tables for multi-row results. Include specific numbers with units ($, %, count). Be concise. Never ask follow-up questions."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "query_sales_data",
        "description": "Query e-commerce sales data. Use for ALL questions about revenue, orders, customers, products, discounts. Dimensions: customer_name, segment (Enterprise/Mid-Market/SMB), region (US-West/US-East/EU-West/APAC), product_name, category (Widgets/Gadgets/Services), order_date, order_month, order_year. Metrics: total_revenue (net after discounts), total_orders (count), total_units (quantity), total_discount (discount dollars), avg_order_value (average net amount), discount_rate (discount/revenue ratio)."
      }
    }
  ],
  "tool_resources": {
    "query_sales_data": {
      "semantic_view": "SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_SV",
      "execution_environment": { "type": "warehouse", "warehouse": "JKLAHR", "query_timeout": 299 }
    }
  }
}
$$;
