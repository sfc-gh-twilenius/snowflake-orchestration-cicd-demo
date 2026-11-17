-- Declarative pipeline. Demo change for the MR: add AVG_ORDER_VALUE to DT_DAILY_REVENUE.
CREATE OR ALTER DYNAMIC TABLE ORCH_{{ env }}.MART.DT_ORDERS
  TARGET_LAG = DOWNSTREAM
  WAREHOUSE  = ORCH_WH
AS
SELECT payload:order_id::STRING        AS order_id,
       payload:customer_id::INT        AS customer_id,
       payload:order_ts::TIMESTAMP_NTZ AS order_ts,
       payload:amount::NUMBER(10,2)    AS amount,
       payload:status::STRING          AS status
FROM ORCH_{{ env }}.RAW.ORDERS_RAW
QUALIFY ROW_NUMBER() OVER (PARTITION BY payload:order_id::STRING ORDER BY loaded_at DESC) = 1;

CREATE OR ALTER DYNAMIC TABLE ORCH_{{ env }}.MART.DT_DAILY_REVENUE
  TARGET_LAG = '{{ "1 minute" if env == "PROD" else "1 hour" }}'   -- environment-specific freshness
  WAREHOUSE  = ORCH_WH
AS
SELECT o.order_ts::DATE AS order_date,
       c.country,
       COUNT(*)         AS orders,
       SUM(o.amount)    AS revenue,
       ROUND(AVG(o.amount), 2) AS avg_order_value
FROM ORCH_{{ env }}.MART.DT_ORDERS o
JOIN ORCH_{{ env }}.RAW.CUSTOMERS c ON c.customer_id = o.customer_id
WHERE o.status <> 'CANCELLED'
GROUP BY 1, 2;
