{{ config(materialized='table') }}

WITH audit_base AS (
  SELECT 
    UUID_STRING() as execution_id,
    'si_process_audit' as pipeline_name,
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
    'ETL' as process_type,
    'dbt_user' as user_executed,
    'dbt_cloud' as server_name,
    NULL as memory_usage_mb,
    NULL as cpu_usage_percent,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date
  WHERE FALSE -- This ensures no initial records are created
)

SELECT 
  execution_id,
  pipeline_name,
  start_time,
  end_time,
  status,
  error_message,
  records_processed,
  records_successful,
  records_failed,
  processing_duration_seconds,
  source_system,
  target_system,
  process_type,
  user_executed,
  server_name,
  memory_usage_mb,
  cpu_usage_percent,
  load_date,
  update_date
FROM audit_base
