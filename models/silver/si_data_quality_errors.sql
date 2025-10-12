-- Data Quality Errors Table - Must be created second
{{ config(
    materialized='table',
    unique_key='error_id'
) }}

-- Initialize error tracking table structure
SELECT 
    'INIT_' || TO_VARCHAR(CURRENT_TIMESTAMP()) AS error_id,
    'INITIALIZATION' AS source_table,
    'INITIALIZATION' AS source_column,
    'SYSTEM' AS error_type,
    'Table initialization' AS error_description,
    'N/A' AS error_value,
    'N/A' AS expected_format,
    'INIT_RECORD' AS record_identifier,
    CURRENT_TIMESTAMP() AS error_timestamp,
    'INFO' AS severity_level,
    'RESOLVED' AS resolution_status,
    'SYSTEM' AS resolved_by,
    CURRENT_TIMESTAMP() AS resolution_timestamp,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SYSTEM' AS source_system
