{{ config(
    materialized='table',
    pre_hook=None,
    post_hook=None
) }}

-- Audit log table for tracking all transformations
SELECT 
    1 as record_id,
    'INITIAL' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt_system' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE FALSE  -- This ensures no actual data is inserted during initial creation
