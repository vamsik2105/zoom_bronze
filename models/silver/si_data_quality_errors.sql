{{ config(
    materialized='table',
    unique_key='error_id'
) }}

-- Data Quality Errors Table
SELECT 
    CAST(NULL AS VARCHAR(255)) AS error_id,
    CAST(NULL AS VARCHAR(255)) AS source_table,
    CAST(NULL AS VARCHAR(255)) AS source_column,
    CAST(NULL AS VARCHAR(100)) AS error_type,
    CAST(NULL AS VARCHAR(1000)) AS error_description,
    CAST(NULL AS VARCHAR(1000)) AS error_value,
    CAST(NULL AS VARCHAR(500)) AS expected_format,
    CAST(NULL AS VARCHAR(255)) AS record_identifier,
    CAST(NULL AS TIMESTAMP_NTZ) AS error_timestamp,
    CAST(NULL AS VARCHAR(50)) AS severity_level,
    CAST(NULL AS VARCHAR(50)) AS resolution_status,
    CAST(NULL AS VARCHAR(255)) AS resolved_by,
    CAST(NULL AS TIMESTAMP_NTZ) AS resolution_timestamp,
    CAST(NULL AS DATE) AS load_date,
    CAST(NULL AS DATE) AS update_date,
    CAST(NULL AS VARCHAR(255)) AS source_system
WHERE 1=0  -- Empty table structure for initialization
