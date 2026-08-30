-- =============================================================================
-- CLEANUP: Reset the entire demo environment
-- Run this to tear down everything and prepare for a fresh demo.
-- Execute in order from top to bottom.
-- =============================================================================

-- ─── Step 1: Drop dbt project objects ─────────────────────────────────────────
DROP DBT PROJECT IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV.ECOM_ANALYTICS_DEV;
DROP DBT PROJECT IF EXISTS SEMANTIC_SKILLS.DBT_SV.ECOM_ANALYTICS;

-- ─── Step 2: Drop the agent ──────────────────────────────────────────────────
DROP AGENT IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS.SALES_ANALYTICS_AGENT;

-- ─── Step 3: Drop the Git integration ─────────────────────────────────────────
DROP GIT REPOSITORY IF EXISTS SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO;
-- Note: We keep the API integration (github_api_int) since it's reusable

-- ─── Step 4: Drop all schemas created by the demo ─────────────────────────────
-- Dev environment
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV_ANALYTICS CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV_STAGING CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV_RAW CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_DEV CASCADE;

-- Prod environment
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_STAGING CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV_RAW CASCADE;
DROP SCHEMA IF EXISTS SEMANTIC_SKILLS.DBT_SV CASCADE;

-- ─── Step 5: Verify clean state ──────────────────────────────────────────────
-- This should return no rows with DBT_SV in the name
SELECT SCHEMA_NAME FROM SEMANTIC_SKILLS.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME LIKE 'DBT_SV%'
ORDER BY SCHEMA_NAME;

-- =============================================================================
-- Step 6: Reset GitHub repo to initial state (run from terminal)
--
-- This force-pushes main back to the v1-baseline tag (before the discount_rate
-- feature branch was merged), and deletes any leftover feature branches.
-- The repo stays intact but looks brand new for the next demo.
-- =============================================================================
--
-- cd dbt_project/
--
-- # Reset main to the v1-baseline tag
-- git fetch origin --tags
-- git reset --hard v1-baseline
-- git push --force origin main
--
-- # Delete any feature branches
-- git push origin --delete feature/add-discount-rate 2>/dev/null
--
-- =============================================================================
