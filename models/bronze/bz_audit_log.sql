{{ config(
    materialized='table',
    pre_hook="",
    post_hook=""
) }}

-- Bronze Audit Log Table
-- This table tracks processing metadata for all bronze layer transformations
SELECT 
    1 as record_id,
    'AUDIT_LOG_INIT' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'DBT_SYSTEM' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE FALSE -- This ensures no data is inserted during initial creation
