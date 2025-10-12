-- Process audit table for tracking ETL execution
-- This model creates the audit log structure

{{ config(
    materialized='table',
    pre_hook="CREATE TABLE IF NOT EXISTS {{ this }} (
        execution_id VARCHAR(255),
        pipeline_name VARCHAR(255),
        start_time TIMESTAMP_NTZ,
        end_time TIMESTAMP_NTZ,
        status VARCHAR(50),
        error_message VARCHAR(5000),
        records_processed NUMBER,
        records_successful NUMBER,
        records_failed NUMBER,
        processing_duration_seconds NUMBER,
        source_system VARCHAR(255),
        target_system VARCHAR(255),
        process_type VARCHAR(100),
        user_executed VARCHAR(255),
        server_name VARCHAR(255),
        memory_usage_mb NUMBER,
        cpu_usage_percent NUMBER,
        load_date DATE,
        update_date DATE
    )"
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
