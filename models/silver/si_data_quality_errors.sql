{{ config(
    materialized='table'
) }}

-- Data Quality Errors Table - Created to capture validation errors
SELECT 
    'INIT-001' as error_id,
    'INITIALIZATION' as source_table,
    'SYSTEM' as source_column,
    'SYSTEM' as error_type,
    'Initial setup' as error_description,
    'N/A' as error_value,
    'N/A' as expected_format,
    'INIT' as record_identifier,
    CURRENT_TIMESTAMP() as error_timestamp,
    'LOW' as severity_level,
    'RESOLVED' as resolution_status,
    'SYSTEM' as resolved_by,
    CURRENT_TIMESTAMP() as resolution_timestamp,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SYSTEM' as source_system
WHERE FALSE -- This ensures no initial record is created
