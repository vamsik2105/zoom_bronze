-- Process audit table for tracking ETL execution
-- This model creates the audit log structure

{{ config(
    materialized='table'
) }}

SELECT 
    execution_id,
    pipeline_name,
    start_time,
    end_time,
    status,
    error_message,
    records_processed,
    records_successful,
    records_failed,
    processing_duration_seconds,
    source_system,
    target_system,
    process_type,
    user_executed,
    server_name,
    memory_usage_mb,
    cpu_usage_percent,
    load_date,
    update_date
FROM (
    SELECT 
        'INITIAL_SETUP' as execution_id,
        'AUDIT_TABLE_CREATION' as pipeline_name,
        CURRENT_TIMESTAMP as start_time,
        CURRENT_TIMESTAMP as end_time,
        'SUCCESS' as status,
        NULL as error_message,
        0 as records_processed,
        0 as records_successful,
        0 as records_failed,
        0 as processing_duration_seconds,
        'SYSTEM' as source_system,
        'SILVER' as target_system,
        'SETUP' as process_type,
        'DBT' as user_executed,
        NULL as server_name,
        NULL as memory_usage_mb,
        NULL as cpu_usage_percent,
        CURRENT_DATE as load_date,
        CURRENT_DATE as update_date
) initial_record
