{{
  config(
    materialized='table'
  )
}}

SELECT
  UUID_STRING() as execution_id,
  'INITIAL_SETUP' as pipeline_name,
  CURRENT_TIMESTAMP() as start_time,
  CURRENT_TIMESTAMP() as end_time,
  'SUCCESS' as status,
  NULL as error_message,
  0 as records_processed,
  0 as records_successful,
  0 as records_failed,
  0 as processing_duration_seconds,
  'BRONZE' as source_system,
  'SILVER' as target_system,
  'SETUP' as process_type,
  'SYSTEM' as user_executed,
  'DBT_CLOUD' as server_name,
  NULL as memory_usage_mb,
  NULL as cpu_usage_percent,
  CURRENT_DATE() as load_date,
  CURRENT_DATE() as update_date
WHERE 1=0
