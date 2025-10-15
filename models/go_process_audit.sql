{{ config(
    materialized='table'
) }}

SELECT 
    'AUDIT_001' AS execution_id,
    'Gold Layer Transform' AS pipeline_name,
    'DBT Model Build' AS process_type,
    CURRENT_TIMESTAMP() AS start_time,
    NULL AS end_time,
    'STARTED' AS status,
    NULL AS error_message,
    0 AS records_processed,
    0 AS records_successful,
    0 AS records_failed,
    0 AS processing_duration_seconds,
    'SILVER' AS source_system,
    'GOLD' AS target_system,
    'dbt_user' AS user_executed,
    'dbt_server' AS server_name,
    0 AS memory_usage_mb,
    0.0 AS cpu_usage_percent,
    0.0 AS data_volume_gb,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date
