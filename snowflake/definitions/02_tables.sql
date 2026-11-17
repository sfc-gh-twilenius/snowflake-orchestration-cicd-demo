-- CREATE OR ALTER = declarative: adding a column here becomes ALTER TABLE ADD COLUMN, data is kept
CREATE OR ALTER TABLE ORCH_{{ env }}.RAW.ORDERS_RAW (
  payload   VARIANT,
  source    STRING,
  loaded_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
) CHANGE_TRACKING = TRUE;

CREATE OR ALTER TABLE ORCH_{{ env }}.RAW.CUSTOMERS (
  customer_id   INT,
  customer_name STRING,
  country       STRING,
  segment       STRING
) CHANGE_TRACKING = TRUE;

CREATE OR ALTER TABLE ORCH_{{ env }}.OPS.DEPLOY_LOG (
  env STRING, deployed_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), deployed_by STRING
);

-- Idempotent reference/sample data (only inserted into an empty environment)
INSERT INTO ORCH_{{ env }}.RAW.CUSTOMERS
SELECT SEQ4() + 1, 'Customer ' || (SEQ4() + 1),
       ARRAY_CONSTRUCT('FI','SE','NO','DK','EE')[UNIFORM(0, 4, RANDOM())]::STRING,
       ARRAY_CONSTRUCT('SMB','MID','ENTERPRISE')[UNIFORM(0, 2, RANDOM())]::STRING
FROM TABLE(GENERATOR(ROWCOUNT => 200))
WHERE NOT EXISTS (SELECT 1 FROM ORCH_{{ env }}.RAW.CUSTOMERS);

INSERT INTO ORCH_{{ env }}.RAW.ORDERS_RAW (payload, source)
SELECT OBJECT_CONSTRUCT('order_id', UUID_STRING(), 'customer_id', UNIFORM(1, 200, RANDOM()),
                        'order_ts', DATEADD('minute', -UNIFORM(0, 10000, RANDOM()), CURRENT_TIMESTAMP())::STRING,
                        'amount', ROUND(UNIFORM(5::FLOAT, 500::FLOAT, RANDOM()), 2),
                        'status', ARRAY_CONSTRUCT('NEW','PAID','SHIPPED','CANCELLED')[UNIFORM(0, 3, RANDOM())]::STRING),
       'SEED'
FROM TABLE(GENERATOR(ROWCOUNT => 2000))
WHERE NOT EXISTS (SELECT 1 FROM ORCH_{{ env }}.RAW.ORDERS_RAW);
