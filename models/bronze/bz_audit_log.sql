{{ config(
    materialized='table'
) }}

-- Bronze Audit Log Table
-- This table tracks all bronze layer processing activities

SELECT 
    CAST(NULL AS NUMBER) AS record_id,
    CAST('INITIAL_LOAD' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP as load_timestamp,
    'dbt' as processed_by,
    CAST(0 AS NUMBER) as processing_time,
    'INITIALIZED' as status

WHERE FALSE -- This ensures the table structure is created but no initial data is inserted
