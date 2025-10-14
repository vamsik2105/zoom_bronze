{{ config(
    materialized='table'
) }}

SELECT 
    '{{ invocation_id }}' as execution_id,
    'Gold Layer Processing' as pipeline_name,
    'DBT_RUN' as process_type,
    CURRENT_TIMESTAMP() as start_time,
    NULL as end_time,
    'INITIALIZED' as status,
    NULL as error_message,
    0 as records_processed,
    0 as records_successful,
    0 as records_failed,
    0 as processing_duration_seconds,
    'SILVER' as source_system,
    'GOLD' as target_system,
    'DBT_CLOUD' as user_executed,
    'SNOWFLAKE' as server_name,
    0 as memory_usage_mb,
    0.0 as cpu_usage_percent,
    0.0 as data_volume_gb,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date
WHERE FALSE
