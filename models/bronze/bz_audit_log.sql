{{ config(
    materialized='table',
    unique_key='record_id'
) }}

-- Create the audit log table if it doesn't exist
-- This will be used to track the processing of all bronze models
SELECT
    1 as record_id,
    'initial_setup' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'initialized' as status
