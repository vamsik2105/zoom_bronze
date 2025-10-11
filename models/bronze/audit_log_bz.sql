{{ config(
    materialized='table',
    pre_hook="",
    post_hook=""
) }}

-- Audit Log Table for Bronze Layer
-- This table tracks all data transformations and loads
SELECT 
    1 as AUDIT_ID,
    'SYSTEM' as SOURCE_LAYER,
    'SYSTEM_INIT' as SOURCE_TABLE,
    'BRONZE' as TARGET_LAYER,
    'AUDIT_LOG_BZ' as TARGET_TABLE,
    'FULL' as LOAD_TYPE,
    CURRENT_TIMESTAMP as LOAD_START_TIME,
    CURRENT_TIMESTAMP as LOAD_END_TIME,
    0 as RECORD_COUNT_LOADED,
    'SUCCESS' as STATUS,
    NULL as ERROR_MESSAGE,
    '{{ invocation_id }}' as RUN_ID,
    CURRENT_USER() as CREATED_BY,
    CURRENT_TIMESTAMP as CREATED_AT
WHERE FALSE  -- This ensures no actual records are inserted during model creation
