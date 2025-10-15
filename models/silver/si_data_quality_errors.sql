{{ config(
    materialized='incremental',
    unique_key='error_id',
    on_schema_change='fail'
) }}

-- Data Quality Errors Table
WITH error_base AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['CURRENT_TIMESTAMP()', "'si_data_quality_errors'", 'RANDOM()']) }} AS error_id,
        'PLACEHOLDER' AS source_table,
        'PLACEHOLDER' AS source_column,
        'PLACEHOLDER' AS error_type,
        'PLACEHOLDER' AS error_description,
        'PLACEHOLDER' AS error_value,
        'PLACEHOLDER' AS expected_format,
        'PLACEHOLDER' AS record_identifier,
        CURRENT_TIMESTAMP() AS error_timestamp,
        'LOW' AS severity_level,
        'OPEN' AS resolution_status,
        NULL AS resolved_by,
        NULL AS resolution_timestamp,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'System' AS source_system
    WHERE 1=0  -- This ensures no placeholder records are inserted
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

{% if is_incremental() %}
    WHERE error_timestamp > (SELECT COALESCE(MAX(error_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
