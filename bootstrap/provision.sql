-- =============================================================================
-- PROVISION: Infrastructure that must exist BEFORE dbt runs
--
-- dbt manages models; it does not manage the schemas, integrations, or Git
-- connection it needs to run inside Snowflake. Run this once per environment.
--
-- Replace the placeholders below to match your account:
--   SEMANTIC_SKILLS  -> your database
--   ACCOUNTADMIN     -> your role
--   YOUR_GH_USERNAME -> your GitHub username
-- =============================================================================

-- ─── 1. Base schemas ─────────────────────────────────────────────────────────
-- DBT_SV holds the dbt project + Git repo objects.
-- DBT_SV_ANALYTICS must be pre-created: CREATE DBT PROJECT validates the
-- project on creation, and that validation resolves the semantic view's target
-- schema before any model has run.
CREATE SCHEMA IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV;
CREATE SCHEMA IF NOT EXISTS SEMANTIC_SKILLS.DBT_SV_ANALYTICS;

-- ─── 2. Materialization privilege ────────────────────────────────────────────
-- Required for the declarative sv_materializations block in the SV model.
GRANT ADD SEMANTIC VIEW MATERIALIZATION
  ON SCHEMA SEMANTIC_SKILLS.DBT_SV_ANALYTICS
  TO ROLE ACCOUNTADMIN;

-- ─── 3. External access for dbt Hub ──────────────────────────────────────────
-- The managed dbt runtime downloads packages.yml dependencies at run time.
-- Check for an existing integration first: SHOW EXTERNAL ACCESS INTEGRATIONS;
CREATE NETWORK RULE IF NOT EXISTS dbt_hub_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'github.com', 'codeload.github.com');

CREATE EXTERNAL ACCESS INTEGRATION IF NOT EXISTS dbt_ext_access
  ALLOWED_NETWORK_RULES = (dbt_hub_network_rule)
  ENABLED = TRUE;

-- ─── 4. GitHub connection ────────────────────────────────────────────────────
-- Public repo, so no SECRET / ALLOWED_AUTHENTICATION_SECRETS needed. For a
-- private repo, create a SECRET with a PAT and reference it on both objects.
CREATE OR REPLACE API INTEGRATION github_api_int
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/YOUR_GH_USERNAME/')
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO
  API_INTEGRATION = github_api_int
  ORIGIN = 'https://github.com/YOUR_GH_USERNAME/dbt-semantic-view-demo.git';

-- Snowflake caches the repo; FETCH after every push you want to deploy.
ALTER GIT REPOSITORY SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO FETCH;

-- ─── 5. Verify ───────────────────────────────────────────────────────────────
-- Expect the dbt project files plus bootstrap/ and agent/.
LS @SEMANTIC_SKILLS.DBT_SV.DBT_SV_REPO/branches/main/;

-- =============================================================================
-- Next: deploy the project (Phase 2 of WALKTHROUGH.md)
-- =============================================================================
