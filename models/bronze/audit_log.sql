{{config(
    materialized='table'
)}}

-- Create audit log table if it doesn't exist
SELECT
    'initial' as audit_id,
    'initial' as model_name,
    CURRENT_TIMESTAMP() as process_timestamp,
    'initial' as process_status,
    0 as record_count,
    NULL as error_message
