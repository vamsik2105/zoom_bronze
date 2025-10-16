{{ config(
    materialized='table'
) }}

SELECT
    'AUDIT_INIT' as process_id,
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
