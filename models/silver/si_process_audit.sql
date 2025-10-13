{{ config(
    materialized='table',
    pre_hook=none,
    post_hook=none
) }}

-- Process Audit Table - Created first to support other models
SELECT 
    CAST(NULL AS STRING) as execution_id,
    CAST(NULL AS STRING) as pipeline_name,
    CAST(NULL AS TIMESTAMP_NTZ) as start_time,
    CAST(NULL AS TIMESTAMP_NTZ) as end_time,
    CAST(NULL AS STRING) as status,
    CAST(NULL AS STRING) as error_message,
    CAST(NULL AS NUMBER) as records_processed,
    CAST(NULL AS NUMBER) as records_successful,
    CAST(NULL AS NUMBER) as records_failed,
    CAST(NULL AS NUMBER) as processing_duration_seconds,
    CAST(NULL AS VARCHAR(255)) as source_system,
    CAST(NULL AS VARCHAR(255)) as target_system,
    CAST(NULL AS STRING) as process_type,
    CAST(NULL AS STRING) as user_executed,
    CAST(NULL AS STRING) as server_name,
    CAST(NULL AS NUMBER) as memory_usage_mb,
    CAST(NULL AS NUMBER) as cpu_usage_percent,
    CAST(NULL AS DATE) as load_date,
    CAST(NULL AS DATE) as update_date
WHERE 1=0  -- Empty table structure
