-- Process Audit Table for ETL Monitoring
{{ config(
    materialized='table',
    unique_key='execution_id'
) }}

SELECT 
    {{ dbt_utils.generate_surrogate_key(['CURRENT_TIMESTAMP()']) }} AS execution_id,
    'zoom_analytics' AS pipeline_name,
    CURRENT_TIMESTAMP() AS start_time,
    CURRENT_TIMESTAMP() AS end_time,
    'SUCCESS' AS status,
    NULL AS error_message,
    0 AS records_processed,
    0 AS records_successful,
    0 AS records_failed,
    0 AS processing_duration_seconds,
    'BRONZE' AS source_system,
    'SILVER' AS target_system,
    'ETL' AS process_type,
    'dbt_user' AS user_executed,
    'dbt_cloud' AS server_name,
    NULL AS memory_usage_mb,
    NULL AS cpu_usage_percent,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date
WHERE 1=0  -- Empty initialization table
