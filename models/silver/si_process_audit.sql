{{ config(
    materialized='incremental',
    unique_key='execution_id',
    on_schema_change='fail'
) }}

-- Process Audit Table - Must run first to avoid dependency issues
WITH audit_base AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['CURRENT_TIMESTAMP()', "'si_process_audit'", 'RANDOM()']) }} AS execution_id,
        'Zoom_Customer_Analytics' AS pipeline_name,
        CURRENT_TIMESTAMP() AS start_time,
        CURRENT_TIMESTAMP() AS end_time,
        'RUNNING' AS status,
        NULL AS error_message,
        0 AS records_processed,
        0 AS records_successful,
        0 AS records_failed,
        0 AS processing_duration_seconds,
        'Bronze' AS source_system,
        'Silver' AS target_system,
        'ETL' AS process_type,
        'dbt_cloud' AS user_executed,
        'dbt_cloud_server' AS server_name,
        NULL AS memory_usage_mb,
        NULL AS cpu_usage_percent,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
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

{% if is_incremental() %}
    WHERE start_time > (SELECT MAX(start_time) FROM {{ this }})
{% endif %}
