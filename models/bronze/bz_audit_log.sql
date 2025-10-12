{{ config(
    materialized='table',
    pre_hook="",
    post_hook=""
) }}

-- Audit log table to track processing information
-- This table must be created first before any other bronze models
SELECT 
    1 as record_id,
    CAST('INITIAL' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    CAST('DBT_SYSTEM' AS VARCHAR(100)) as processed_by,
    CAST(0 AS NUMBER) as processing_time,
    CAST('INITIALIZED' AS VARCHAR(50)) as status
WHERE FALSE  -- This ensures no actual data is inserted during initial creation
