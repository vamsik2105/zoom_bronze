-- Process Audit Table - Must be created first
{{ config(
    materialized='table',
    unique_key='execution_id'
) }}

-- Initialize audit table structure
SELECT 
    'INIT_' || TO_VARCHAR(CURRENT_TIMESTAMP()) AS execution_id,
    'INITIALIZATION' AS pipeline_name,
    CURRENT_TIMESTAMP() AS start_time,
    CURRENT_TIMESTAMP() AS end_time,
    'SUCCESS' AS status,
    NULL AS error_message,
    0 AS records_processed,
    0 AS records_successful,
    0 AS records_failed,
    0 AS processing_duration_seconds,
    'SYSTEM' AS source_system,
    'SILVER' AS target_system,
    'INITIALIZATION' AS process_type,
    'dbt_system' AS user_executed,
    'dbt_cloud' AS server_name,
    NULL AS memory_usage_mb,
    NULL AS cpu_usage_percent,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date
