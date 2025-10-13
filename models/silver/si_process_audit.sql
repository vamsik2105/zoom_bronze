{{ config(materialized='table') }}

WITH audit_base AS (
    SELECT 
        'INIT' AS execution_id,
        'INITIALIZATION' AS pipeline_name,
        CURRENT_TIMESTAMP() AS start_time,
        CURRENT_TIMESTAMP() AS end_time,
        'SUCCESS' AS status,
        NULL AS error_message,
        0 AS records_processed,
        0 AS records_successful,
        0 AS records_failed,
        0 AS processing_duration_seconds,
        'SYSTEM' AS source_system,
        'SILVER' AS target_system,
        'INITIALIZATION' AS process_type,
        'SYSTEM' AS user_executed,
        'DBT_CLOUD' AS server_name,
        0 AS memory_usage_mb,
        0 AS cpu_usage_percent,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    WHERE 1=0  -- This ensures no rows are inserted during initial creation
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
