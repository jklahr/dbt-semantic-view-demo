-- =============================================================================
-- TEARDOWN: Drop everything the demo created
--
-- Run top to bottom. Safe to re-run — every statement is IF EXISTS.
-- Step 7 (Git reset) runs from your terminal, not Snowflake.
-- =============================================================================

-- ─── 1. dbt project objects ──────────────────────────────────────────────────
DROP DBT PROJECT IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV.ECOM_ANALYTICS_DEV;
DROP DBT PROJECT IF EXISTS SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS;

-- ─── 2. Agent + evaluation objects ───────────────────────────────────────────
-- NOTE: EXECUTE_AI_EVALUATION('DELETE', ...) hangs; don't call it. Dropping the
-- agent and dataset is enough — orphaned runs are harmless, and re-running the
-- demo uses a fresh run_name anyway.
DROP AGENT   IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_AGENT;
DROP DATASET IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALSET;
DROP TABLE   IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_AGENT_EVALS;
DROP STAGE   IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.EVAL_CONFIG_STAGE;

-- ─── 3. Git repository ───────────────────────────────────────────────────────
-- The API integration (github_api_int) is left in place — it's reusable and
-- account-scoped.
DROP GIT REPOSITORY IF EXISTS SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO;

-- ─── 4. Dev schemas ──────────────────────────────────────────────────────────
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV_ANALYTICS CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV_STAGING   CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV_RAW       CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV           CASCADE;

-- ─── 5. Prod schemas ─────────────────────────────────────────────────────────
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_STAGING   CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_RAW       CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV           CASCADE;

-- ─── 6. Verify ───────────────────────────────────────────────────────────────
-- Expect zero rows.
SELECT SCHEMA_NAME
FROM SEMANTIC_SKILLS.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME LIKE 'DBT_SV%'
ORDER BY SCHEMA_NAME;

-- =============================================================================
-- 7. Reset the Git repo (terminal, from the repo root)
--
--   git fetch origin --tags
--   git reset --hard v1-baseline
--   git push --force origin main
--   git push origin --delete feature/add-discount-rate
--
-- This rewinds main to the pre-feature state so the walkthrough's Phase 4
-- (add discount_rate on a branch, promote to prod) can be replayed from
-- scratch. The repo and its history stay intact.
-- =============================================================================
