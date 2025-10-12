-- Process audit table for tracking ETL execution
-- This model creates the audit log structure

{{ config(
    materialized='table'
) }}

SELECT 
    'INITIAL_SETUP' as execution_id,
    'AUDIT_TABLE_CREATION' as pipeline_name,
    CURRENT_TIMESTAMP as start_time,
    CURRENT_TIMESTAMP as end_time,
    'SUCCESS' as status,
    CAST(NULL AS STRING) as error_message,
    0 as records_processed,
    0 as records_successful,
    0 as records_failed,
    0 as processing_duration_seconds,
    'SYSTEM' as source_system,
    'SILVER' as target_system,
    'SETUP' as process_type,
    'DBT' as user_executed,
    CAST(NULL AS STRING) as server_name,
    CAST(NULL AS NUMBER) as memory_usage_mb,
    CAST(NULL AS NUMBER) as cpu_usage_percent,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date
