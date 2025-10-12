-- =====================================================
-- DATA QUALITY ERRORS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

-- Base structure for data quality errors
SELECT 
    CAST('INITIAL_SETUP' AS STRING) as error_id,
    CAST('INITIAL_SETUP' AS VARCHAR(255)) as source_table,
    CAST('INITIAL_SETUP' AS VARCHAR(255)) as source_column,
    CAST('SETUP' AS VARCHAR(100)) as error_type,
    CAST('Initial setup record' AS VARCHAR(500)) as error_description,
    CAST('N/A' AS VARCHAR(500)) as error_value,
    CAST('N/A' AS VARCHAR(255)) as expected_format,
    CAST('SETUP' AS VARCHAR(255)) as record_identifier,
    CURRENT_TIMESTAMP() as error_timestamp,
    CAST('LOW' AS VARCHAR(50)) as severity_level,
    CAST('RESOLVED' AS VARCHAR(50)) as resolution_status,
    CAST('SYSTEM' AS VARCHAR(100)) as resolved_by,
    CURRENT_TIMESTAMP() as resolution_timestamp,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    CAST('SYSTEM' AS VARCHAR(100)) as source_system

WHERE FALSE -- This creates the structure without inserting any records initially
