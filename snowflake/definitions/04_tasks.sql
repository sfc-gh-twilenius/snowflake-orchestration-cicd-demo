-- Tasks: the root must be suspended before any task in its graph can be altered.
ALTER TASK IF EXISTS ORCH_{{ env }}.OPS.T00_DAILY_SNAPSHOT SUSPEND;

CREATE OR ALTER TABLE ORCH_{{ env }}.MART.REVENUE_SNAPSHOT (
  snapshot_date DATE, country STRING, revenue NUMBER(14,2), taken_at TIMESTAMP_LTZ
);

CREATE OR ALTER TASK ORCH_{{ env }}.OPS.T00_DAILY_SNAPSHOT
  SCHEDULE = 'USING CRON 0 5 * * * Europe/Helsinki'
  USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
AS
  INSERT INTO ORCH_{{ env }}.MART.REVENUE_SNAPSHOT
  SELECT CURRENT_DATE(), country, SUM(revenue), CURRENT_TIMESTAMP()
  FROM ORCH_{{ env }}.MART.DT_DAILY_REVENUE
  GROUP BY 2;

CREATE OR ALTER TASK ORCH_{{ env }}.OPS.T10_PURGE_OLD_SNAPSHOTS
  WAREHOUSE = ORCH_WH
  AFTER ORCH_{{ env }}.OPS.T00_DAILY_SNAPSHOT
AS
  DELETE FROM ORCH_{{ env }}.MART.REVENUE_SNAPSHOT WHERE snapshot_date < DATEADD('day', -90, CURRENT_DATE());

{% if env == 'PROD' %}
-- Only production runs on a schedule; DEV / MR clones stay suspended (no surprise cost)
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE('ORCH_{{ env }}.OPS.T00_DAILY_SNAPSHOT');
{% endif %}

INSERT INTO ORCH_{{ env }}.OPS.DEPLOY_LOG (env, deployed_by) SELECT '{{ env }}', CURRENT_USER();
