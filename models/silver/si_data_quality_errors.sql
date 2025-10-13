{{ config(materialized='table') }}

-- Data Quality Errors Table
SELECT 
    CAST(NULL AS STRING) as error_id,
    CAST(NULL AS VARCHAR(255)) as source_table,
    CAST(NULL AS VARCHAR(255)) as source_column,
    CAST(NULL AS STRING) as error_type,
    CAST(NULL AS STRING) as error_description,
    CAST(NULL AS STRING) as error_value,
    CAST(NULL AS STRING) as expected_format,
    CAST(NULL AS STRING) as record_identifier,
    CAST(NULL AS TIMESTAMP_NTZ) as error_timestamp,
    CAST(NULL AS STRING) as severity_level,
    CAST(NULL AS STRING) as resolution_status,
    CAST(NULL AS STRING) as resolved_by,
    CAST(NULL AS TIMESTAMP_NTZ) as resolution_timestamp,
    CAST(NULL AS DATE) as load_date,
    CAST(NULL AS DATE) as update_date,
    CAST(NULL AS VARCHAR(255)) as source_system
WHERE 1=0  -- Empty table structure
