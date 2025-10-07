-- Create the audit log table first as it will be referenced by other models
-- This table tracks the processing of all other models

{{ config(
    materialized = 'table',
    pre_hook = """
        -- No pre-hook needed for audit log as it's the first table
    """,
    post_hook = """
        -- No post-hook needed for audit log
    """
) }}

-- Initialize the audit log table if it doesn't exist
SELECT
    NULL as record_id,
    'INITIALIZATION' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'SYSTEM' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE NOT EXISTS (SELECT 1 FROM {{ this }})
