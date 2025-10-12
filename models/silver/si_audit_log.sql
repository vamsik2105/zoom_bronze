{{ config(
    materialized='table'
) }}

-- Audit log table for tracking all transformations
SELECT 
    CAST(1 AS NUMBER) as record_id,
    CAST('INITIAL' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    CAST('dbt_system' AS VARCHAR(100)) as processed_by,
    CAST(0 AS NUMBER) as processing_time,
    CAST('INITIALIZED' AS VARCHAR(50)) as status
WHERE 1=0  -- This ensures no actual data is inserted during initial creation
