{{
  config(
    materialized='table',
    pre_hook=None,
    post_hook=None
  )
}}

-- Process Audit Table - Created first to support other models
WITH audit_base AS (
  SELECT 
    '{{ invocation_id }}' as execution_id,
    'sv_process_audit' as pipeline_name,
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
    'dbt' as user_executed,
    'dbt_cloud' as server_name,
    NULL as memory_usage_mb,
    NULL as cpu_usage_percent,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date
  WHERE FALSE -- This ensures no rows are inserted initially
)

SELECT 
  execution_id::VARCHAR(255) as execution_id,
  pipeline_name::VARCHAR(255) as pipeline_name,
  start_time,
  end_time,
  status::VARCHAR(50) as status,
  error_message::VARCHAR(1000) as error_message,
  records_processed,
  records_successful,
  records_failed,
  processing_duration_seconds,
  source_system::VARCHAR(255) as source_system,
  target_system::VARCHAR(255) as target_system,
  process_type::VARCHAR(50) as process_type,
  user_executed::VARCHAR(255) as user_executed,
  server_name::VARCHAR(255) as server_name,
  memory_usage_mb,
  cpu_usage_percent,
  load_date,
  update_date
FROM audit_base
