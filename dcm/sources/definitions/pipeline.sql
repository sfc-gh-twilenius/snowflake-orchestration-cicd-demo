-- DCM variant of the same pipeline: pure desired state. `snow dcm plan` shows the diff, `deploy` applies it.
-- Objects removed from these files are dropped on deploy - the project owns them.
DEFINE DATABASE ORCH_DCM{{ env_suffix }};
DEFINE SCHEMA ORCH_DCM{{ env_suffix }}.RAW;
DEFINE SCHEMA ORCH_DCM{{ env_suffix }}.MART;

DEFINE TABLE ORCH_DCM{{ env_suffix }}.RAW.ORDERS_RAW (
  payload VARIANT, source STRING, loaded_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
) CHANGE_TRACKING = TRUE;

DEFINE TABLE ORCH_DCM{{ env_suffix }}.RAW.CUSTOMERS (
  customer_id INT, customer_name STRING, country STRING, segment STRING
) CHANGE_TRACKING = TRUE;

DEFINE DYNAMIC TABLE ORCH_DCM{{ env_suffix }}.MART.DT_DAILY_REVENUE
  TARGET_LAG = '{{ target_lag }}'
  WAREHOUSE  = {{ warehouse }}
AS
SELECT o.payload:order_ts::DATE AS order_date, c.country,
       COUNT(*) AS orders, SUM(o.payload:amount::NUMBER(10,2)) AS revenue
FROM ORCH_DCM{{ env_suffix }}.RAW.ORDERS_RAW o
JOIN ORCH_DCM{{ env_suffix }}.RAW.CUSTOMERS c ON c.customer_id = o.payload:customer_id::INT
GROUP BY 1, 2;

DEFINE TASK ORCH_DCM{{ env_suffix }}.MART.T_DAILY_CHECK
  SCHEDULE = 'USING CRON 0 7 * * * Europe/Helsinki'
  {{ task_state }}
AS
  SELECT COUNT(*) FROM ORCH_DCM{{ env_suffix }}.MART.DT_DAILY_REVENUE;
