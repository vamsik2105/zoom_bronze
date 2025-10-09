{{ config(
    materialized='table'
) }}

-- Simple audit log table
SELECT 
    1 as record_id,
    'INITIAL_LOAD' as source_table,
    CURRENT_TIMESTAMP as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
