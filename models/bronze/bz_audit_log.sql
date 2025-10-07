-- Create audit log table for tracking bronze layer transformations

{{ config(
    materialized = 'table',
    tags = ['bronze', 'audit']
) }}

-- Create the audit log table from scratch without dependencies
SELECT
    1 as record_id,
    'INITIALIZATION' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_USER() as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE 1=0  -- Initialize empty table
