{{ config(
    materialized='table'
) }}

SELECT 
    UUID_STRING() as process_id,
    'audit_initialization' as process_name,
    'system' as source_table,
    'go_process_audit' as target_table,
    'INITIALIZED' as process_status,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    0 as records_processed,
    CAST(NULL AS VARCHAR(255)) as error_message,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at
