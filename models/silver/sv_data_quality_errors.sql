{{
  config(
    materialized='table'
  )
}}

-- Data Quality Errors Table
WITH error_base AS (
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
)

SELECT 
  error_id::VARCHAR(255) as error_id,
  source_table::VARCHAR(255) as source_table,
  source_column::VARCHAR(255) as source_column,
  error_type::VARCHAR(100) as error_type,
  error_description::VARCHAR(1000) as error_description,
  error_value::VARCHAR(500) as error_value,
  expected_format::VARCHAR(500) as expected_format,
  record_identifier::VARCHAR(255) as record_identifier,
  error_timestamp,
  severity_level::VARCHAR(50) as severity_level,
  resolution_status::VARCHAR(50) as resolution_status,
  resolved_by::VARCHAR(255) as resolved_by,
  resolution_timestamp,
  load_date,
  update_date,
  source_system::VARCHAR(255) as source_system
FROM error_base
