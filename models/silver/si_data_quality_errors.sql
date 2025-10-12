{{ config(
    materialized='table'
) }}

-- Data quality errors tracking table
SELECT 
    {{ dbt_utils.generate_surrogate_key(['source_table', 'error_type', 'current_timestamp()']) }} as error_id,
    CAST('PLACEHOLDER' AS VARCHAR(255)) as source_table,
    CAST('PLACEHOLDER' AS VARCHAR(100)) as source_column,
    CAST('PLACEHOLDER' AS VARCHAR(100)) as error_type,
    CAST('PLACEHOLDER' AS VARCHAR(500)) as error_description,
    CAST('PLACEHOLDER' AS VARCHAR(500)) as error_value,
    CAST('PLACEHOLDER' AS VARCHAR(200)) as expected_format,
    CAST('PLACEHOLDER' AS VARCHAR(100)) as record_identifier,
    CURRENT_TIMESTAMP() as error_timestamp,
    CAST('LOW' AS VARCHAR(20)) as severity_level,
    CAST('OPEN' AS VARCHAR(20)) as resolution_status,
    CAST(NULL AS VARCHAR(100)) as resolved_by,
    CAST(NULL AS TIMESTAMP_NTZ) as resolution_timestamp,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    CAST('dbt_system' AS VARCHAR(100)) as source_system
WHERE 1=0  -- This ensures no actual data is inserted during initial creation
