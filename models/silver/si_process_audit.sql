{{ config(materialized='table') }}

-- Process Audit Table - Created first to support other models
SELECT 
    CAST('init' AS STRING) as execution_id,
    CAST('initialization' AS STRING) as pipeline_name,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    CAST('SUCCESS' AS STRING) as status,
    CAST(NULL AS STRING) as error_message,
    CAST(0 AS NUMBER) as records_processed,
    CAST(0 AS NUMBER) as records_successful,
    CAST(0 AS NUMBER) as records_failed,
    CAST(0 AS NUMBER) as processing_duration_seconds,
    CAST('SYSTEM' AS VARCHAR(255)) as source_system,
    CAST('SILVER' AS VARCHAR(255)) as target_system,
    CAST('INIT' AS STRING) as process_type,
    CAST('dbt' AS STRING) as user_executed,
    CAST('dbt_cloud' AS STRING) as server_name,
    CAST(NULL AS NUMBER) as memory_usage_mb,
    CAST(NULL AS NUMBER) as cpu_usage_percent,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date
WHERE 1=0  -- Empty table structure
