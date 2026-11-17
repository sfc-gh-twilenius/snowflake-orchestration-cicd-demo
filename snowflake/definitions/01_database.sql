-- One database per environment: ORCH_DEV, ORCH_PROD, ORCH_MR_<iid> (zero-copy clone of PROD)
CREATE DATABASE IF NOT EXISTS ORCH_{{ env }};
CREATE OR ALTER SCHEMA ORCH_{{ env }}.RAW;
CREATE OR ALTER SCHEMA ORCH_{{ env }}.MART;
CREATE OR ALTER SCHEMA ORCH_{{ env }}.OPS;
