{{ config(
    materialized='table',
    unique_key='execution_id'
) }}

-- Process Audit Table - Must run first to avoid dependency issues
SELECT 
    CAST(NULL AS VARCHAR(255)) AS execution_id,
    CAST(NULL AS VARCHAR(255)) AS pipeline_name,
    CAST(NULL AS TIMESTAMP_NTZ) AS start_time,
    CAST(NULL AS TIMESTAMP_NTZ) AS end_time,
    CAST(NULL AS VARCHAR(50)) AS status,
    CAST(NULL AS VARCHAR(1000)) AS error_message,
    CAST(NULL AS NUMBER) AS records_processed,
    CAST(NULL AS NUMBER) AS records_successful,
    CAST(NULL AS NUMBER) AS records_failed,
    CAST(NULL AS NUMBER) AS processing_duration_seconds,
    CAST(NULL AS VARCHAR(255)) AS source_system,
    CAST(NULL AS VARCHAR(255)) AS target_system,
    CAST(NULL AS VARCHAR(100)) AS process_type,
    CAST(NULL AS VARCHAR(255)) AS user_executed,
    CAST(NULL AS VARCHAR(255)) AS server_name,
    CAST(NULL AS NUMBER) AS memory_usage_mb,
    CAST(NULL AS NUMBER) AS cpu_usage_percent,
    CAST(NULL AS DATE) AS load_date,
    CAST(NULL AS DATE) AS update_date
WHERE 1=0  -- This creates an empty table with the correct schema
