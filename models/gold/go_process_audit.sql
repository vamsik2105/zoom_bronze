{{ config(
    materialized='table'
) }}

-- Gold Process Audit Table
-- This table tracks all transformation processes from Silver to Gold layer

SELECT 
    'INIT' as execution_id,
    'INITIALIZATION' as pipeline_name,
    'SETUP' as process_type,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    'COMPLETED' as status,
    NULL as error_message,
    0 as records_processed,
    0 as records_successful,
    0 as records_failed,
    0 as processing_duration_seconds,
    'SYSTEM' as source_system,
    'GOLD' as target_system,
    'DBT' as user_executed,
    'DBT_CLOUD' as server_name,
    NULL as memory_usage_mb,
    NULL as cpu_usage_percent,
    NULL as data_volume_gb,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date
