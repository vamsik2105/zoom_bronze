-- Create audit log table for tracking bronze layer transformations

{{ config(
    materialized = 'table',
    tags = ['bronze', 'audit']
) }}

-- Create the audit log table from scratch
SELECT
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as record_id,
    NULL as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_USER() as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE 1=0  -- Initialize empty table
