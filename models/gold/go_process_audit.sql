{{ config(
    materialized='table'
) }}

SELECT 
    CAST(NULL AS VARCHAR(50)) as execution_id,
    CAST(NULL AS VARCHAR(255)) as pipeline_name,
    CAST(NULL AS VARCHAR(100)) as process_type,
    CAST(NULL AS TIMESTAMP_NTZ) as start_time,
    CAST(NULL AS TIMESTAMP_NTZ) as end_time,
    CAST(NULL AS VARCHAR(50)) as status,
    CAST(NULL AS VARCHAR(2000)) as error_message,
    CAST(NULL AS NUMBER) as records_processed,
    CAST(NULL AS NUMBER) as records_successful,
    CAST(NULL AS NUMBER) as records_failed,
    CAST(NULL AS NUMBER) as processing_duration_seconds,
    CAST(NULL AS VARCHAR(100)) as source_system,
    CAST(NULL AS VARCHAR(100)) as target_system,
    CAST(NULL AS VARCHAR(100)) as user_executed,
    CAST(NULL AS VARCHAR(100)) as server_name,
    CAST(NULL AS NUMBER) as memory_usage_mb,
    CAST(NULL AS NUMBER(5,2)) as cpu_usage_percent,
    CAST(NULL AS NUMBER(10,2)) as data_volume_gb,
    CAST(NULL AS DATE) as load_date,
    CAST(NULL AS DATE) as update_date
WHERE 1=0
