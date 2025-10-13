{{ config(materialized='table') }}

WITH audit_base AS (
    SELECT 
        'init' as execution_id,
        'initialization' as pipeline_name,
        CURRENT_TIMESTAMP() as start_time,
        CURRENT_TIMESTAMP() as end_time,
        'SUCCESS' as status,
        NULL as error_message,
        0 as records_processed,
        0 as records_successful,
        0 as records_failed,
        0 as processing_duration_seconds,
        'SYSTEM' as source_system,
        'SILVER' as target_system,
        'INITIALIZATION' as process_type,
        'DBT' as user_executed,
        'DBT_CLOUD' as server_name,
        NULL as memory_usage_mb,
        NULL as cpu_usage_percent,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date
    WHERE 1=0  -- This ensures no initial records are created
)

SELECT 
    execution_id::VARCHAR(255),
    pipeline_name::VARCHAR(255),
    start_time,
    end_time,
    status::VARCHAR(50),
    error_message::VARCHAR(1000),
    records_processed,
    records_successful,
    records_failed,
    processing_duration_seconds,
    source_system::VARCHAR(255),
    target_system::VARCHAR(255),
    process_type::VARCHAR(100),
    user_executed::VARCHAR(255),
    server_name::VARCHAR(255),
    memory_usage_mb,
    cpu_usage_percent,
    load_date,
    update_date
FROM audit_base
