-- =============================================================================
-- FULL DEMO: End-to-end in one script
-- Prerequisites: provision.sql has been run, GitHub repo exists with code pushed.
-- This runs the entire lifecycle: deploy v1 → feature branch → promote to prod.
-- =============================================================================

USE DATABASE SEMANTIC_SKILLS;
USE WAREHOUSE JKLAHR;  -- Replace with your warehouse

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHASE 2: Deploy v1 to Production
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO FETCH;

CREATE OR REPLACE DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS
  FROM '@SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO/branches/main/'
  DEFAULT_TARGET = 'prod'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_EXT_ACCESS);

EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS ARGS = 'seed';
EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS ARGS = 'run';
EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS ARGS = 'test';

-- Verify SV works
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_SV
    DIMENSIONS customers.customer_name, customers.segment
    METRICS orders.total_revenue, orders.total_orders
) ORDER BY TOTAL_REVENUE DESC;

-- Verify materializations
SHOW MATERIALIZATIONS IN SEMANTIC VIEW SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_SV;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHASE 2.5: Create Agent + Baseline Eval
-- ═══════════════════════════════════════════════════════════════════════════════

-- Create the agent
CREATE OR REPLACE AGENT SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_AGENT
  COMMENT = 'E-commerce analytics agent powered by the sales_analytics_sv semantic view.'
  PROFILE = '{"display_name": "Sales Analytics"}'
  FROM SPECIFICATION $$
{
  "models": { "orchestration": "auto" },
  "instructions": {
    "orchestration": "You are the Sales Analytics Agent for an e-commerce business.\n\nCRITICAL: ALWAYS call the query_sales_data tool to answer ANY question. NEVER ask clarifying questions. The semantic view contains ALL the data you need.",
    "response": "Lead with the direct answer. Use tables for multi-row results. Include specific numbers with units ($, %, count). Be concise."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "query_sales_data",
        "description": "Query e-commerce sales data. Dimensions: customer_name, segment, region, product_name, category, order_date, order_month, order_year. Metrics: total_revenue, total_orders, total_units, total_discount, avg_order_value, discount_rate."
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

-- Create eval dataset
CREATE OR REPLACE TABLE SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS (
    INPUT_QUERY VARCHAR,
    GROUND_TRUTH_DATA VARIANT
);

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

CALL SYSTEM$CREATE_EVALUATION_DATASET(
    'Cortex Agent',
    'SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS',
    'SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALSET',
    OBJECT_CONSTRUCT('query_text', 'INPUT_QUERY', 'expected_tools', 'GROUND_TRUTH_DATA')
);

-- Upload eval config and run baseline
CREATE OR REPLACE STAGE SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE DIRECTORY = (ENABLE = TRUE);
-- NOTE: Upload eval_config.yaml to the stage before running:
--   snow stage copy setup/eval_config.yaml @SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE

CALL EXECUTE_AI_EVALUATION(
  'START',
  OBJECT_CONSTRUCT('run_name', 'BASELINE_V1'),
  '@SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE/eval_config.yaml'
);

-- Check status (re-run until COMPLETED)
CALL EXECUTE_AI_EVALUATION(
  'STATUS',
  OBJECT_CONSTRUCT('run_name', 'BASELINE_V1'),
  '@SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE/eval_config.yaml'
);

-- View baseline scores
SELECT METRIC_NAME, ROUND(AVG(EVAL_AGG_SCORE), 3) AS avg_score
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_EVALUATION_DATA(
  'SEMANTIC_SKILLS', 'DBT_SV_ANALYTICS', 'SALES_ANALYTICS_AGENT', 'cortex agent', 'BASELINE_V1'
))
GROUP BY METRIC_NAME ORDER BY METRIC_NAME;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHASE 3: Feature Branch (run git commands in terminal between SQL steps)
-- ═══════════════════════════════════════════════════════════════════════════════

-- After: git checkout -b feature/add-discount-rate
--        (edit sales_analytics_sv.sql to add discount_rate metric)
--        git add -A && git commit -m "feat: add discount_rate metric"
--        git push -u origin feature/add-discount-rate

-- Deploy feature branch to dev
CREATE SCHEMA IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV_DEV;

ALTER GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO FETCH;

CREATE OR REPLACE DBT PROJECT SEMANTIC_SKILLS.DBT_SV_DEV.ECOM_ANALYTICS_DEV
  FROM '@SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO/branches/"feature/add-discount-rate"/'
  DEFAULT_TARGET = 'dev'
  EXTERNAL_ACCESS_INTEGRATIONS = (DBT_EXT_ACCESS);

EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV_DEV.ECOM_ANALYTICS_DEV ARGS = 'seed';
EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV_DEV.ECOM_ANALYTICS_DEV ARGS = 'run';
EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV_DEV.ECOM_ANALYTICS_DEV ARGS = 'test';

-- Verify new metric in dev
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC_SKILLS.DBT_SV_DEV_ANALYTICS.SALES_ANALYTICS_SV
    DIMENSIONS customers.segment
    METRICS orders.total_revenue, orders.discount_rate
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PHASE 4: Promote to Production
-- ═══════════════════════════════════════════════════════════════════════════════

-- After: gh pr create --title "feat: add discount_rate" --base main --head feature/add-discount-rate
--        gh pr merge --squash --delete-branch

ALTER GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO FETCH;

ALTER DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS
  ADD VERSION
  FROM '@SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO/branches/main/';

EXECUTE DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS ARGS = 'run';

-- Verify in production
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_SV
    DIMENSIONS customers.customer_name
    METRICS orders.total_revenue, orders.discount_rate
) ORDER BY TOTAL_REVENUE DESC;

-- Show version history
SHOW VERSIONS IN DBT PROJECT SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS;

-- ═══════════════════════════════════════════════════════════════════════════════
-- DONE! Run setup/cleanup.sql to reset for next demo.
-- ═══════════════════════════════════════════════════════════════════════════════
