{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ this }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) SELECT '{{ invocation_id }}', 'Gold Layer Transform', 'Dimension Build', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE() WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ this }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
) }}

SELECT 
    CAST('INIT' AS VARCHAR(50)) AS execution_id,
    CAST('Gold Layer Transform' AS VARCHAR(200)) AS pipeline_name,
    CAST('Dimension Build' AS VARCHAR(100)) AS process_type,
    CURRENT_TIMESTAMP() AS start_time,
    CAST(NULL AS TIMESTAMP_NTZ) AS end_time,
    CAST('INITIALIZED' AS VARCHAR(50)) AS status,
    CAST(NULL AS VARCHAR(2000)) AS error_message,
    CAST(0 AS NUMBER) AS records_processed,
    CAST(0 AS NUMBER) AS records_successful,
    CAST(0 AS NUMBER) AS records_failed,
    CAST(0 AS NUMBER) AS processing_duration_seconds,
    CAST('SILVER' AS VARCHAR(100)) AS source_system,
    CAST('GOLD' AS VARCHAR(100)) AS target_system,
    CAST('DBT_USER' AS VARCHAR(100)) AS user_executed,
    CAST('DBT_CLOUD' AS VARCHAR(100)) AS server_name,
    CAST(0 AS NUMBER) AS memory_usage_mb,
    CAST(0.0 AS NUMBER(5,2)) AS cpu_usage_percent,
    CAST(0.0 AS NUMBER(10,2)) AS data_volume_gb,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date
WHERE FALSE
