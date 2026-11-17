-- =====================================================================
-- CI service users - one per trust boundary (run as ACCOUNTADMIN; review first)
-- OIDC / Workload Identity Federation: no stored secret. Snowflake matches issuer + subject
-- of the CI job's short-lived ID token to exactly one user. Subjects are exact (no wildcards).
-- =====================================================================
USE ROLE ACCOUNTADMIN;

-- ---------- GitLab ----------
-- main branch -> DEV + PROD deployments
CREATE USER IF NOT EXISTS SVC_GITLAB_CI
  TYPE = SERVICE
  DEFAULT_ROLE = ORCH_DEPLOYER
  DEFAULT_WAREHOUSE = ORCH_WH
  COMMENT = 'GitLab CI (main branch) via OIDC'
  WORKLOAD_IDENTITY = (
    TYPE = OIDC
    ISSUER = 'https://gitlab.com'                                  -- self-managed: your instance URL
    SUBJECT = 'project_path:<group>/<project>:ref_type:branch:ref:main'
  );
GRANT ROLE ORCH_DEPLOYER TO USER SVC_GITLAB_CI;

-- Merge-request pipelines: GitLab's subject is the *source branch*, which changes per MR and
-- can't be wildcarded. Use a separate, lower-privilege user with key-pair auth (private key as a
-- masked GitLab *File* variable). Or: restrict MR validation to protected 'develop' branch + OIDC.
CREATE ROLE IF NOT EXISTS ORCH_MR_DEPLOYER;          -- may only create/drop ORCH_MR_* clones
GRANT CREATE DATABASE ON ACCOUNT TO ROLE ORCH_MR_DEPLOYER;
GRANT USAGE ON WAREHOUSE ORCH_WH TO ROLE ORCH_MR_DEPLOYER;
GRANT USAGE ON DATABASE ORCH_OPS TO ROLE ORCH_MR_DEPLOYER;
GRANT USAGE ON SCHEMA ORCH_OPS.GIT TO ROLE ORCH_MR_DEPLOYER;
GRANT READ, WRITE ON GIT REPOSITORY ORCH_OPS.GIT.ORCH_REPO TO ROLE ORCH_MR_DEPLOYER;
-- Clone source: needs read on PROD (CLONE needs USAGE + SELECT-level privileges on source objects)
GRANT USAGE ON DATABASE ORCH_PROD TO ROLE ORCH_MR_DEPLOYER;
GRANT USAGE ON ALL SCHEMAS IN DATABASE ORCH_PROD TO ROLE ORCH_MR_DEPLOYER;
GRANT SELECT ON ALL TABLES IN DATABASE ORCH_PROD TO ROLE ORCH_MR_DEPLOYER;
GRANT SELECT ON ALL DYNAMIC TABLES IN DATABASE ORCH_PROD TO ROLE ORCH_MR_DEPLOYER;

CREATE USER IF NOT EXISTS SVC_GITLAB_MR
  TYPE = SERVICE
  DEFAULT_ROLE = ORCH_MR_DEPLOYER
  DEFAULT_WAREHOUSE = ORCH_WH
  RSA_PUBLIC_KEY = '<public key body>'
  COMMENT = 'GitLab merge-request pipelines (ephemeral clones only)';
GRANT ROLE ORCH_MR_DEPLOYER TO USER SVC_GITLAB_MR;

-- ---------- GitHub (live demo variant) ----------
-- NOTE: newer GitHub repos/orgs send *immutable* subjects that include numeric IDs, e.g.
--   repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:refs/heads/main
-- Copy the exact subject from the first failed `snow connection test` error if unsure.
-- GitHub's PR subject is stable ('pull_request'), so both users can be OIDC.
CREATE USER IF NOT EXISTS SVC_GITHUB_MAIN
  TYPE = SERVICE DEFAULT_ROLE = ORCH_DEPLOYER DEFAULT_WAREHOUSE = ORCH_WH
  WORKLOAD_IDENTITY = (TYPE = OIDC ISSUER = 'https://token.actions.githubusercontent.com'
                       SUBJECT = 'repo:<owner>/<repo>:ref:refs/heads/main');
GRANT ROLE ORCH_DEPLOYER TO USER SVC_GITHUB_MAIN;

CREATE USER IF NOT EXISTS SVC_GITHUB_PR
  TYPE = SERVICE DEFAULT_ROLE = ORCH_MR_DEPLOYER DEFAULT_WAREHOUSE = ORCH_WH
  WORKLOAD_IDENTITY = (TYPE = OIDC ISSUER = 'https://token.actions.githubusercontent.com'
                       SUBJECT = 'repo:<owner>/<repo>:pull_request');
GRANT ROLE ORCH_MR_DEPLOYER TO USER SVC_GITHUB_PR;

-- ---------- Network policy note ----------
-- GitHub-hosted runners: allow SNOWFLAKE.NETWORK_SECURITY.GITHUBACTIONS_GLOBAL (managed rule).
-- GitLab.com shared runners: no managed rule yet -> prefer self-managed runners with static egress IPs.
