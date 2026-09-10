-- =============================================================================
-- RUN EVAL: execute the quality gate and read the scores
--
-- Prereqs: create_agent.sql and eval_dataset.sql have run.
-- =============================================================================

-- ─── 1. Stage the config ─────────────────────────────────────────────────────
CREATE STAGE IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE
  DIRECTORY = (ENABLE = TRUE);

-- Upload from your terminal:
--   snow stage copy agent/eval_config.yaml \
--     @SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE --overwrite

-- ─── 2. Session context is REQUIRED ──────────────────────────────────────────
-- EXECUTE_AI_EVALUATION creates and drops scratch objects. Without a current
-- database it fails with:
--   "Cannot perform DROP. This session does not have a current database."
USE DATABASE SEMANTIC_SKILLS;
USE SCHEMA DBT_SV_ANALYTICS;
USE WAREHOUSE JKLAHR;

-- ─── 3. Start the run ────────────────────────────────────────────────────────
-- Signature: (action, run_parameters OBJECT, config_file_path VARCHAR)
CALL EXECUTE_AI_EVALUATION(
  'START',
  OBJECT_CONSTRUCT('run_name', 'BASELINE_V1'),
  '@SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE/eval_config.yaml'
);

-- ─── 4. Poll until COMPLETED ─────────────────────────────────────────────────
-- ~90-120s for 8 questions. Progression:
--   CREATED -> INVOCATION_IN_PROGRESS -> INVOCATION_COMPLETED
--           -> COMPUTATION_IN_PROGRESS -> COMPLETED
CALL EXECUTE_AI_EVALUATION(
  'STATUS',
  OBJECT_CONSTRUCT('run_name', 'BASELINE_V1'),
  '@SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE/eval_config.yaml'
);

-- ─── 5. Read the scores ──────────────────────────────────────────────────────
SELECT METRIC_NAME,
       ROUND(AVG(EVAL_AGG_SCORE), 3) AS avg_score,
       COUNT(*)                      AS records
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_EVALUATION_DATA(
  'SEMANTIC_SKILLS', 'DBT_SV_ANALYTICS', 'SALES_ANALYTICS_AGENT',
  'cortex agent', 'BASELINE_V1'
))
GROUP BY METRIC_NAME
ORDER BY METRIC_NAME;

-- Reference baseline (validated Sept 2026):
--   answer_correctness   1.000
--   logical_consistency  ~0.79-0.92   (reference-free, varies run to run)

-- ─── 6. Debug a zero score ───────────────────────────────────────────────────
-- METRIC_STATUS carries the actual error. An empty GROUND_TRUTH plus
-- "Missing ground truth: ground_truth_output not found" means the JSON keys or
-- the column_mapping in eval_dataset.sql are wrong.
SELECT INPUT,
       GROUND_TRUTH,
       OUTPUT,
       EVAL_AGG_SCORE,
       METRIC_STATUS::VARCHAR AS status_detail
FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_EVALUATION_DATA(
  'SEMANTIC_SKILLS', 'DBT_SV_ANALYTICS', 'SALES_ANALYTICS_AGENT',
  'cortex agent', 'BASELINE_V1'
))
WHERE METRIC_NAME = 'answer_correctness';

-- =============================================================================
-- Re-running: use a NEW run_name. Do NOT call EXECUTE_AI_EVALUATION('DELETE'),
-- which hangs. Orphaned runs are harmless.
-- =============================================================================
