{{ config(
    materialized='table',
    unique_key='record_id'
) }}

-- Create the audit log table if it doesn't exist
-- This will be used to track the processing of all bronze models
SELECT
    NULL as record_id,
    'initial_setup' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'initialized' as status
WHERE 1=0  -- Empty initial table, will be populated by pre/post hooks
