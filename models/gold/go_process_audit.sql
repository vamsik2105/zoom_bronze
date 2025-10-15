{{ config(
    materialized='table'
) }}

WITH audit_base AS (
    SELECT 
        UUID_STRING() AS process_id,
        'process_audit_setup' AS process_name,
        'SYSTEM' AS source_table,
        'go_process_audit' AS target_table,
        'COMPLETED' AS process_status,
        CURRENT_TIMESTAMP() AS start_time,
        CURRENT_TIMESTAMP() AS end_time,
        1 AS records_processed,
        CAST(NULL AS VARCHAR(500)) AS error_message,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'DBT_SYSTEM' AS source_system
)

SELECT 
    process_id,
    process_name,
    CAST(source_table AS VARCHAR(255)) AS source_table,
    CAST(target_table AS VARCHAR(255)) AS target_table,
    CAST(process_status AS VARCHAR(50)) AS process_status,
    start_time,
    end_time,
    records_processed,
    error_message,
    load_date,
    update_date,
    CAST(source_system AS VARCHAR(100)) AS source_system
FROM audit_base
