{{ config(
    materialized='table'
) }}

-- Audit log table for tracking bronze layer processes
SELECT 
    CAST('audit_log' AS STRING) as table_name,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP_NTZ) as process_start_time,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP_NTZ) as process_end_time,
    CAST('SUCCESS' AS STRING) as status,
    CAST('Audit log initialized' AS STRING) as message,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP_NTZ) as created_at
WHERE FALSE -- This ensures no actual data is inserted during model creation
