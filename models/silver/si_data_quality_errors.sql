{{
  config(
    materialized='table'
  )
}}

-- Data quality errors tracking table
SELECT 
    'INITIAL' as error_id,
    'SYSTEM' as source_table,
    'SYSTEM' as source_column,
    'SETUP' as error_type,
    'Initial setup record' as error_description,
    'N/A' as error_value,
    'N/A' as expected_format,
    'SYSTEM' as record_identifier,
    CURRENT_TIMESTAMP as error_timestamp,
    'INFO' as severity_level,
    'RESOLVED' as resolution_status,
    'SYSTEM' as resolved_by,
    CURRENT_TIMESTAMP as resolution_timestamp,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    'SYSTEM' as source_system
WHERE FALSE -- This ensures the initial record is only created once
