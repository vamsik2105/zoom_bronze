{{ config(
    materialized='table'
) }}

-- Process Audit Table for Gold Layer
SELECT 
    'INIT' AS execution_id,
    'INITIALIZATION' AS pipeline_name,
    'DBT_MODEL' AS process_type,
    CURRENT_TIMESTAMP() AS start_time,
    CURRENT_TIMESTAMP() AS end_time,
    'COMPLETED' AS status,
    NULL AS error_message,
    0 AS records_processed,
    0 AS records_successful,
    0 AS records_failed,
    0 AS processing_duration_seconds,
    'SILVER' AS source_system,
    'GOLD' AS target_system,
    'DBT_CLOUD' AS user_executed,
    'DBT_SERVER' AS server_name,
    NULL AS memory_usage_mb,
    NULL AS cpu_usage_percent,
    NULL AS data_volume_gb,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date
