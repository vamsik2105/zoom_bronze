{{
  config(
    materialized='table'
  )
}}

SELECT
  UUID_STRING() as error_id,
  CAST('INITIAL_SETUP' AS VARCHAR(255)) as source_table,
  CAST('SETUP' AS VARCHAR(255)) as source_column,
  'SETUP' as error_type,
  'Initial table setup' as error_description,
  'N/A' as error_value,
  'N/A' as expected_format,
  'SETUP' as record_identifier,
  CURRENT_TIMESTAMP() as error_timestamp,
  'LOW' as severity_level,
  'RESOLVED' as resolution_status,
  'SYSTEM' as resolved_by,
  CURRENT_TIMESTAMP() as resolution_timestamp,
  CURRENT_DATE() as load_date,
  CURRENT_DATE() as update_date,
  'SYSTEM' as source_system
WHERE 1=0
