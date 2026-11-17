-- =====================================================================
-- deploy.sql  -  single entry point, executed INSIDE Snowflake from the Git repository clone:
--   EXECUTE IMMEDIATE FROM @ORCH_OPS.GIT.ORCH_REPO/commits/<sha>/snowflake/deploy.sql USING (env => 'PROD');
-- Every definition is idempotent (CREATE OR ALTER / IF NOT EXISTS) -> safe to re-run.
-- =====================================================================
EXECUTE IMMEDIATE FROM './definitions/01_database.sql'       USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM './definitions/02_tables.sql'         USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM './definitions/03_dynamic_tables.sql' USING (env => '{{ env }}');
EXECUTE IMMEDIATE FROM './definitions/04_tasks.sql'          USING (env => '{{ env }}');
