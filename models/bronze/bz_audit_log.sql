-- Audit log model for tracking bronze layer transformations
-- This model must be created first before other bronze models

{{ config(
    materialized='table'
) }}

-- Create the audit log table structure
SELECT 
    ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP()) as record_id,
    CAST('INITIAL_LOAD' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE FALSE -- This ensures no actual data is inserted during initial creation

-- Union with a single initialization record
UNION ALL

SELECT 
    1 as record_id,
    CAST('AUDIT_LOG_INIT' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status