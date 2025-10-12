-- Data quality errors table for tracking validation issues
-- This model creates the error log structure

{{ config(
    materialized='table'
) }}

SELECT 
    'INITIAL_SETUP' as error_id,
    'SYSTEM' as source_table,
    'SETUP' as source_column,
    'SETUP' as error_type,
    'Initial error log table creation' as error_description,
    'N/A' as error_value,
    'N/A' as expected_format,
    'SETUP' as record_identifier,
    CURRENT_TIMESTAMP as error_timestamp,
    'Info' as severity_level,
    'Resolved' as resolution_status,
    'DBT' as resolved_by,
    CURRENT_TIMESTAMP as resolution_timestamp,
    CURRENT_DATE as load_date,
    CURRENT_DATE as update_date,
    'SYSTEM' as source_system
