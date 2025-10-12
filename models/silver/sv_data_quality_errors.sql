{{
  config(
    materialized='table'
  )
}}

-- Data Quality Errors table to capture all validation failures
SELECT 
    CAST(NULL AS STRING) as error_id,
    CAST(NULL AS VARCHAR(255)) as source_table,
    CAST(NULL AS VARCHAR(255)) as source_column,
    CAST(NULL AS VARCHAR(100)) as error_type,
    CAST(NULL AS VARCHAR(500)) as error_description,
    CAST(NULL AS VARCHAR(500)) as error_value,
    CAST(NULL AS VARCHAR(255)) as expected_format,
    CAST(NULL AS VARCHAR(255)) as record_identifier,
    CAST(NULL AS TIMESTAMP_NTZ) as error_timestamp,
    CAST(NULL AS VARCHAR(50)) as severity_level,
    CAST(NULL AS VARCHAR(50)) as resolution_status,
    CAST(NULL AS VARCHAR(100)) as resolved_by,
    CAST(NULL AS TIMESTAMP_NTZ) as resolution_timestamp,
    CAST(NULL AS DATE) as load_date,
    CAST(NULL AS DATE) as update_date,
    CAST(NULL AS VARCHAR(100)) as source_system
WHERE FALSE -- This ensures the table structure is created but no initial data
