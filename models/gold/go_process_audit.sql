{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ this }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, created_at, updated_at) VALUES (UUID_STRING(), 'gold_transformation', 'multiple_silver_tables', 'go_process_audit', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()) WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ this }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), updated_at = CURRENT_TIMESTAMP() WHERE process_status = 'STARTED' AND target_table != 'go_process_audit'"
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
    NULL as error_message,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at
