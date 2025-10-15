{{ config(
    materialized='table'
) }}

SELECT 
    'PROC_INIT_001' as process_id,
    'Initial Audit Setup' as process_name,
    'SYSTEM' as source_table,
    'go_process_audit' as target_table,
    'INITIALIZED' as process_status,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    1 as records_processed,
    NULL as error_message,
    CURRENT_DATE() as load_date
