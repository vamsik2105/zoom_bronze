-- Data Quality Errors Table
{{ config(
    materialized='table',
    unique_key='error_id'
) }}

SELECT 
    {{ dbt_utils.generate_surrogate_key(['CURRENT_TIMESTAMP()']) }} AS error_id,
    'test_table' AS source_table,
    'test_column' AS source_column,
    'test_error' AS error_type,
    'test_description' AS error_description,
    'test_value' AS error_value,
    'test_format' AS expected_format,
    'test_record' AS record_identifier,
    CURRENT_TIMESTAMP() AS error_timestamp,
    'LOW' AS severity_level,
    'OPEN' AS resolution_status,
    NULL AS resolved_by,
    NULL AS resolution_timestamp,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'BRONZE' AS source_system
WHERE 1=0  -- Empty initialization table
