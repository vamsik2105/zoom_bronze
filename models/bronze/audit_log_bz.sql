{{ config(
    materialized='table',
    pre_hook="",
    post_hook=""
) }}

-- Audit Log Table for Bronze Layer
-- This table tracks all data transformations and loads
SELECT 
    CAST(1 AS NUMBER) as AUDIT_ID,
    CAST('SYSTEM' AS VARCHAR(255)) as SOURCE_LAYER,
    CAST('SYSTEM_INIT' AS VARCHAR(255)) as SOURCE_TABLE,
    CAST('BRONZE' AS VARCHAR(255)) as TARGET_LAYER,
    CAST('AUDIT_LOG_BZ' AS VARCHAR(255)) as TARGET_TABLE,
    CAST('FULL' AS VARCHAR(50)) as LOAD_TYPE,
    CURRENT_TIMESTAMP as LOAD_START_TIME,
    CURRENT_TIMESTAMP as LOAD_END_TIME,
    CAST(0 AS NUMBER) as RECORD_COUNT_LOADED,
    CAST('SUCCESS' AS VARCHAR(50)) as STATUS,
    CAST(NULL AS VARCHAR(1000)) as ERROR_MESSAGE,
    CAST('{{ invocation_id }}' AS VARCHAR(255)) as RUN_ID,
    CURRENT_USER() as CREATED_BY,
    CURRENT_TIMESTAMP as CREATED_AT
WHERE FALSE  -- This ensures no actual records are inserted during model creation
