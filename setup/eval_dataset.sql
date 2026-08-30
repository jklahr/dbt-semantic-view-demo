-- =============================================================================
-- EVAL DATASET: Sales Analytics Agent Evaluation Questions
-- These are the "acceptance tests" for the semantic layer + agent combination.
-- Run this AFTER the agent has been created.
-- =============================================================================

-- Create the eval table
CREATE TABLE IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS (
    INPUT_QUERY VARCHAR,
    GROUND_TRUTH_DATA VARIANT
);

-- Clear existing data (idempotent)
TRUNCATE TABLE IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS;

-- ─── Baseline eval questions (v1: covers all original metrics) ────────────────

INSERT INTO SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS (INPUT_QUERY, GROUND_TRUTH_DATA)
SELECT 'What is the total revenue?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "The total revenue is $3,314.50."}')
UNION ALL
SELECT 'What is the total revenue by customer segment?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "Revenue by segment: Enterprise $1,784.74, Mid-Market $1,019.82, SMB $509.94."}')
UNION ALL
SELECT 'Which customer has the highest revenue?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "Delta Co has the highest revenue at $1,149.80."}')
UNION ALL
SELECT 'How many orders are there in total?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "There are 15 orders in total."}')
UNION ALL
SELECT 'What is the revenue breakdown by product category?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "Revenue by category: Widgets $1,264.62, Services $809.96, Gadgets $1,239.92."}')
UNION ALL
SELECT 'What is the average order value?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "The average order value is approximately $220.97."}')
UNION ALL
SELECT 'What is the total discount amount?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "The total discount amount is $195.00."}')
UNION ALL
SELECT 'Show me revenue by region',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "Revenue by region: US-West $634.94, US-East $1,594.70, EU-West $509.94, APAC $574.92."}');

-- ─── Create the evaluation dataset object ─────────────────────────────────────

CALL SYSTEM$CREATE_EVALUATION_DATASET(
    'Cortex Agent',
    'SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS',
    'SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALSET',
    OBJECT_CONSTRUCT('query_text', 'INPUT_QUERY', 'expected_tools', 'GROUND_TRUTH_DATA')
);
