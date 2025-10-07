-- Create the audit log table first as it will be referenced by other models
-- This table tracks the processing of all other models

{{ config(
    materialized = 'table'
) }}

-- Initialize the audit log table
SELECT
    NULL as record_id,
    'INITIALIZATION' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'SYSTEM' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE 1=0
