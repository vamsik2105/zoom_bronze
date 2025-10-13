{{ config(materialized='table') }}

-- Data Quality Errors Table
SELECT 
    CAST('init' AS STRING) as error_id,
    CAST('init' AS VARCHAR(255)) as source_table,
    CAST('init' AS VARCHAR(255)) as source_column,
    CAST('init' AS STRING) as error_type,
    CAST('init' AS STRING) as error_description,
    CAST('init' AS STRING) as error_value,
    CAST('init' AS STRING) as expected_format,
    CAST('init' AS STRING) as record_identifier,
    CURRENT_TIMESTAMP() as error_timestamp,
    CAST('LOW' AS STRING) as severity_level,
    CAST('OPEN' AS STRING) as resolution_status,
    CAST(NULL AS STRING) as resolved_by,
    CAST(NULL AS TIMESTAMP_NTZ) as resolution_timestamp,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    CAST('SYSTEM' AS VARCHAR(255)) as source_system
WHERE 1=0  -- Empty table structure
