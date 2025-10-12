{{
  config(
    materialized='table'
  )
}}

-- Audit log table to track all transformations
SELECT 
    1 as record_id,
    'sv_audit_log' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt_system' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE FALSE -- This ensures the table structure is created but no initial data
