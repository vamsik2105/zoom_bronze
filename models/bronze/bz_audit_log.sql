{{ config(
    materialized='table'
) }}

-- Create audit log table structure
SELECT 
    NULL::NUMBER as record_id,
    CAST(NULL AS VARCHAR(255)) as source_table,
    NULL::TIMESTAMP_NTZ as load_timestamp,
    NULL::STRING as processed_by,
    NULL::NUMBER as processing_time,
    NULL::STRING as status
WHERE 1=0  -- This ensures no data is inserted, only structure is created
