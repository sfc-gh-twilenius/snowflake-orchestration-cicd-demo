-- =====================================================================
-- One-time platform setup for Git-based CI/CD (run as ACCOUNTADMIN; review first)
-- Creates: deployer role, Git API integration, Git repository clone in Snowflake
-- =====================================================================
USE ROLE ACCOUNTADMIN;

-- ---------- Deployer role used by every pipeline ----------
CREATE ROLE IF NOT EXISTS ORCH_DEPLOYER;
GRANT ROLE ORCH_DEPLOYER TO ROLE SYSADMIN;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE ORCH_DEPLOYER;
GRANT EXECUTE TASK, EXECUTE MANAGED TASK ON ACCOUNT TO ROLE ORCH_DEPLOYER;
GRANT USAGE ON WAREHOUSE ORCH_WH TO ROLE ORCH_DEPLOYER;

-- ---------- Where the Git clone lives ----------
CREATE DATABASE IF NOT EXISTS ORCH_OPS;
CREATE SCHEMA  IF NOT EXISTS ORCH_OPS.GIT;

-- Private repo: a read-only token. GitLab: project access token (read_repository).
-- GitHub: fine-grained PAT (Contents: read). Public repo: skip the secret entirely.
CREATE OR REPLACE SECRET ORCH_OPS.GIT.GIT_READ_TOKEN
  TYPE = PASSWORD
  USERNAME = '<gitlab-or-github-username>'
  PASSWORD = '<read-only token>';

CREATE OR REPLACE API INTEGRATION ORCH_GIT_API
  API_PROVIDER = GIT_HTTPS_API
  API_ALLOWED_PREFIXES = ('https://gitlab.com/<group>', 'https://github.com/<owner>')
  ALLOWED_AUTHENTICATION_SECRETS = (ORCH_OPS.GIT.GIT_READ_TOKEN)
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY ORCH_OPS.GIT.ORCH_REPO
  API_INTEGRATION = ORCH_GIT_API
  GIT_CREDENTIALS = ORCH_OPS.GIT.GIT_READ_TOKEN
  ORIGIN = 'https://gitlab.com/<group>/<project>.git';     -- or https://github.com/<owner>/<repo>.git

GRANT USAGE ON INTEGRATION ORCH_GIT_API TO ROLE ORCH_DEPLOYER;
GRANT USAGE ON DATABASE ORCH_OPS TO ROLE ORCH_DEPLOYER;
GRANT USAGE ON SCHEMA ORCH_OPS.GIT TO ROLE ORCH_DEPLOYER;
GRANT READ, WRITE ON GIT REPOSITORY ORCH_OPS.GIT.ORCH_REPO TO ROLE ORCH_DEPLOYER;   -- WRITE = FETCH

-- ---------- Explore it (great live moment) ----------
ALTER GIT REPOSITORY ORCH_OPS.GIT.ORCH_REPO FETCH;
SHOW GIT BRANCHES IN ORCH_OPS.GIT.ORCH_REPO;
LS @ORCH_OPS.GIT.ORCH_REPO/branches/main/snowflake/;
EXECUTE IMMEDIATE FROM @ORCH_OPS.GIT.ORCH_REPO/branches/main/snowflake/deploy.sql USING (env => 'DEV');
