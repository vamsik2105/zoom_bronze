{{
  config(
    materialized='table'
  )
}}

-- Data Quality Errors Table
SELECT 
  'INIT' as error_id,
  'INIT' as source_table,
  'INIT' as source_column,
  'INIT' as error_type,
  'Initial setup' as error_description,
  'INIT' as error_value,
  'INIT' as expected_format,
  'INIT' as record_identifier,
  CURRENT_TIMESTAMP() as error_timestamp,
  'LOW' as severity_level,
  'RESOLVED' as resolution_status,
  'system' as resolved_by,
  CURRENT_TIMESTAMP() as resolution_timestamp,
  CURRENT_DATE() as load_date,
  CURRENT_DATE() as update_date,
  'SYSTEM' as source_system
WHERE FALSE -- This ensures no rows are inserted initially
