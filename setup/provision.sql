-- =============================================================================
-- SETUP: Provision everything needed for the demo
-- Run this ONCE before starting the walkthrough.
-- Assumes: SEMANTIC_SKILLS database exists, ACCOUNTADMIN role.
-- =============================================================================

-- ─── Step 1: Create base schemas ──────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV;
CREATE SCHEMA IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS;  -- pre-create for CREATE DBT PROJECT validation

-- ─── Step 2: External access for dbt Hub packages ─────────────────────────────
-- Check if one already exists: SHOW EXTERNAL ACCESS INTEGRATIONS;
-- If not, create:
CREATE NETWORK RULE IF NOT EXISTS dbt_hub_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'github.com', 'codeload.github.com');

CREATE EXTERNAL ACCESS INTEGRATION IF NOT EXISTS dbt_ext_access
  ALLOWED_NETWORK_RULES = (dbt_hub_network_rule)
  ENABLED = TRUE;

-- ─── Step 3: Grant materialization privilege ──────────────────────────────────
GRANT ADD SEMANTIC VIEW MATERIALIZATION ON SCHEMA SEMANTIC_SKILLS.DBT_SV_ANALYTICS TO ROLE ACCOUNTADMIN;

-- ─── Step 4: GitHub API integration ──────────────────────────────────────────
-- Replace YOUR_USERNAME with your GitHub username
CREATE OR REPLACE API INTEGRATION github_api_int
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/YOUR_USERNAME/')
  ENABLED = TRUE;

-- ─── Step 5: Git repository ──────────────────────────────────────────────────
-- Replace YOUR_USERNAME with your GitHub username
CREATE OR REPLACE GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO
  API_INTEGRATION = github_api_int
  ORIGIN = 'https://github.com/YOUR_USERNAME/dbt-semantic-view-demo.git';

ALTER GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO FETCH;

-- Verify: should show ~20 files
LS @SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO/branches/main/;

-- =============================================================================
-- You're ready! Continue with Phase 2 of the WALKTHROUGH.md
-- =============================================================================
