-- =============================================================================
-- EVAL DATASET: acceptance tests for the semantic layer + agent
--
-- These questions are the quality gate. Run this AFTER create_agent.sql.
--
-- TWO NON-OBVIOUS REQUIREMENTS (both cause a silent answer_correctness = 0):
--
--   1. The keys INSIDE the ground truth JSON must be exactly
--      `ground_truth_output` (the expected answer) and
--      `ground_truth_invocations` (the expected tool calls, keyed by
--      `tool_name`). `expected_output` / `tool_calls` are silently ignored.
--
--   2. The column_mapping key in SYSTEM$CREATE_EVALUATION_DATASET is
--      `expected_tools` — NOT `ground_truth`. The docs call this out: the
--      system function's mapping keys differ from the YAML dataset spec.
--
-- Debug a 0 score with:
--   SELECT INPUT, METRIC_STATUS::VARCHAR FROM TABLE(
--     SNOWFLAKE.LOCAL.GET_AI_EVALUATION_DATA(...)) WHERE METRIC_NAME='answer_correctness';
-- A mapping problem reports: "Missing ground truth: ground_truth_output not found".
--
-- Also note: PARSE_JSON does not work inside a VALUES clause. Use SELECT ... UNION ALL.
-- =============================================================================

CREATE TABLE IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS (
    INPUT_QUERY       VARCHAR,
    GROUND_TRUTH_DATA VARIANT
);

TRUNCATE TABLE IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS;

-- ─── Baseline questions (v1 metrics) ─────────────────────────────────────────
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
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "Revenue by category: Widgets $1,389.61, Services $1,109.96, Gadgets $814.93."}')
UNION ALL
SELECT 'What is the average order value?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "The average order value is approximately $220.97."}')
UNION ALL
SELECT 'What is the total discount amount?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "The total discount amount is $195.00."}')
UNION ALL
SELECT 'How many units were sold?',
       PARSE_JSON('{"ground_truth_invocations": [{"tool_name": "query_sales_data"}], "ground_truth_output": "A total of 50 units were sold."}');

-- ─── Register the dataset ────────────────────────────────────────────────────
-- A dataset cannot be recreated over itself; DROP first when re-seeding.
DROP DATASET IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALSET;

CALL SYSTEM$CREATE_EVALUATION_DATASET(
    'Cortex Agent',                                          -- dataset type
    'SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS',    -- source table
    'SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALSET',  -- dataset to create
    OBJECT_CONSTRUCT(
        'query_text',     'INPUT_QUERY',
        'expected_tools', 'GROUND_TRUTH_DATA'   -- see note 2 above
    )
);
