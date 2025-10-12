{{
  config(
    materialized='table'
  )
}}

-- Process Audit Table - Created first to support other models
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
