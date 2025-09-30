{{config(
    materialized='table',
    schema='bronze'
)}}

-- Create audit log table if it doesn't exist
CREATE TABLE IF NOT EXISTS {{ this }} (
    audit_id STRING,
    model_name STRING,
    process_timestamp TIMESTAMP_NTZ,
    process_status STRING,
    record_count NUMBER,
    error_message STRING
)
