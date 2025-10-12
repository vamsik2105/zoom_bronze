-- =====================================================
-- AUDIT LOG MODEL - MUST RUN FIRST
-- =====================================================

{{ config(
    materialized='table'
) }}

-- Base audit log structure - this creates the table first
SELECT 
    CAST('INITIAL_SETUP' AS STRING) as execution_id,
    CAST('INITIAL_SETUP' AS STRING) as pipeline_name,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    CAST('SUCCESS' AS STRING) as status,
    CAST(NULL AS STRING) as error_message,
    CAST(0 AS NUMBER) as records_processed,
    CAST(0 AS NUMBER) as records_successful,
    CAST(0 AS NUMBER) as records_failed,
    CAST(0 AS NUMBER) as processing_duration_seconds,
    CAST('SYSTEM' AS STRING) as source_system,
    CAST('SILVER' AS STRING) as target_system,
    CAST('SETUP' AS STRING) as process_type,
    CAST('DBT' AS STRING) as user_executed,
    CAST('DBT_CLOUD' AS STRING) as server_name,
    CAST(NULL AS NUMBER) as memory_usage_mb,
    CAST(NULL AS NUMBER) as cpu_usage_percent,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date
