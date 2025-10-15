{{
    config(
        materialized='incremental',
        unique_key='error_id',
        on_schema_change='fail'
    )
}}

-- Data Quality Errors Table - Captures all DQ violations
SELECT
    {{ dbt_utils.generate_surrogate_key(['CURRENT_TIMESTAMP', 'RANDOM()']) }} AS error_id,
    'INITIAL_SETUP' AS source_table,
    'N/A' AS source_column,
    'SETUP' AS error_type,
    'Initial setup of DQ errors table' AS error_description,
    'N/A' AS error_value,
    'N/A' AS expected_format,
    'SETUP_RECORD' AS record_identifier,
    CURRENT_TIMESTAMP AS error_timestamp,
    'INFO' AS severity_level,
    'RESOLVED' AS resolution_status,
    'SYSTEM' AS resolved_by,
    CURRENT_TIMESTAMP AS resolution_timestamp,
    CURRENT_DATE AS load_date,
    CURRENT_DATE AS update_date,
    'SYSTEM' AS source_system

{% if is_incremental() %}
WHERE FALSE  -- Only insert initial record on first run
{% endif %}
