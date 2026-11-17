# Snowflake orchestration + CI/CD demo

Demo of Git-driven deployments to Snowflake:

- `snowflake/` - idempotent definitions (`CREATE OR ALTER`), Jinja-templated per environment, executed **inside Snowflake** from a Git repository clone with `EXECUTE IMMEDIATE FROM @repo/commits/<sha>/...`
- `.github/workflows/snowflake-cicd.yml` - PR -> zero-copy clone of PROD, deploy + test; `main` -> DEV -> (approval) -> PROD. OIDC / Workload Identity Federation, no stored secrets.
- `.gitlab-ci.yml` - the same flow for GitLab using the `snowflake-dev/snowflake-cicd-component`.
- `dcm/` - the same pipeline as a DCM Project (plan / deploy).
- `setup/` - one-time Snowflake setup templates (replace `<placeholders>`).

Configure the repo variable `SNOWFLAKE_ACCOUNT` (Settings > Secrets and variables > Actions > Variables).
All data is synthetic.
