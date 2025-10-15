{{ config(
    materialized='table',
    cluster_by=['process_date']
) }}

SELECT
    'INIT' as process_id,
    'INITIALIZATION' as process_name,
    'N/A' as source_table,
    'go_process_audit' as target_table,
    'INITIALIZED' as process_status,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    0 as record_count,
    NULL as error_message,
    CURRENT_DATE() as process_date,
    'SYSTEM' as created_by
WHERE FALSE -- This ensures the table structure is created but no initial records

UNION ALL

SELECT
    UUID_STRING() as process_id,
    'AUDIT_TABLE_CREATION' as process_name,
    'N/A' as source_table,
    'go_process_audit' as target_table,
    'COMPLETED' as process_status,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    1 as record_count,
    NULL as error_message,
    CURRENT_DATE() as process_date,
    'SYSTEM' as created_by
