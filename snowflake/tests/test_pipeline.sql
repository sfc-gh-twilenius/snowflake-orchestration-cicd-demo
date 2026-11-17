-- Post-deploy tests. Any RAISE fails the CI job (snow sql exits non-zero).
--   EXECUTE IMMEDIATE FROM @.../snowflake/tests/test_pipeline.sql USING (env => 'MR_42');
DECLARE
  test_failed EXCEPTION (-20001, 'Pipeline test failed - see query history for details');
  n INT;
BEGIN
  -- 1. All expected objects exist
  n := (SELECT COUNT(*) FROM ORCH_{{ env }}.INFORMATION_SCHEMA.TABLES
        WHERE table_schema = 'MART' AND table_name IN ('DT_ORDERS', 'DT_DAILY_REVENUE', 'REVENUE_SNAPSHOT'));
  IF (n <> 3) THEN RAISE test_failed; END IF;

  -- 2. Dynamic tables refresh successfully on the new definition
  ALTER DYNAMIC TABLE ORCH_{{ env }}.MART.DT_DAILY_REVENUE REFRESH;

  -- 3. Data rules
  n := (SELECT COUNT(*) FROM ORCH_{{ env }}.MART.DT_ORDERS WHERE amount < 0 OR order_id IS NULL);
  IF (n > 0) THEN RAISE test_failed; END IF;

  n := (SELECT COUNT(*) FROM (SELECT order_id FROM ORCH_{{ env }}.MART.DT_ORDERS GROUP BY 1 HAVING COUNT(*) > 1));
  IF (n > 0) THEN RAISE test_failed; END IF;

  RETURN 'All pipeline tests passed for ORCH_{{ env }}';
END;
