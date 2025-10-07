-- Create audit log table for tracking bronze layer transformations

{{ config(
    materialized = 'table',
    tags = ['bronze', 'audit']
) }}

-- This is the first model to be created, so no pre/post hooks for audit logging
SELECT
    record_id,
    source_table,
    load_timestamp,
    processed_by,
    processing_time,
    status
FROM {{ source('raw', 'audit_log') }}
WHERE 1=0  -- Initialize empty table if it doesn't exist
