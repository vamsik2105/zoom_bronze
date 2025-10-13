{{ config(materialized='table') }}

WITH error_base AS (
  SELECT 
    UUID_STRING() as error_id,
    'si_data_quality_errors' as source_table,
    'error_id' as source_column,
    'Initialization' as error_type,
    'Initial table creation' as error_description,
    'N/A' as error_value,
    'N/A' as expected_format,
    'INIT' as record_identifier,
    CURRENT_TIMESTAMP() as error_timestamp,
    'Low' as severity_level,
    'Resolved' as resolution_status,
    'system' as resolved_by,
    CURRENT_TIMESTAMP() as resolution_timestamp,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SYSTEM' as source_system
  WHERE FALSE -- This ensures no initial records are created
)

SELECT 
  error_id,
  source_table,
  source_column,
  error_type,
  error_description,
  error_value,
  expected_format,
  record_identifier,
  error_timestamp,
  severity_level,
  resolution_status,
  resolved_by,
  resolution_timestamp,
  load_date,
  update_date,
  source_system
FROM error_base
