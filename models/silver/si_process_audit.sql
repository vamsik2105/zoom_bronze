{{
  config(
    materialized='table'
  )
}}

-- Audit table to track all ETL processes
SELECT 
    '{{ invocation_id }}' || '_INITIAL' as execution_id,
    'INITIAL_SETUP' as pipeline_name,
    CURRENT_TIMESTAMP as start_time,
    CURRENT_TIMESTAMP as end_time,
    'COMPLETED' as status,
    NULL as error_message,
    0 as records_processed,
    0 as records_successful,
    0 as records_failed,
    0 as processing_duration_seconds,
    'SYSTEM' as source_system,
    'SILVER' as target_system,
    'SETUP' as process_type,
    'DBT' as user_executed,
    'DBT_CLOUD' as server_name,
    NULL as memory_usage_mb,
    NULL as cpu_usage_percent,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date
WHERE FALSE -- This ensures the initial record is only created once
