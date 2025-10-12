-- Data quality errors table for tracking validation issues
-- This model creates the error log structure

{{ config(
    materialized='table',
    pre_hook="CREATE TABLE IF NOT EXISTS {{ this }} (
        error_id VARCHAR(255),
        source_table VARCHAR(255),
        source_column VARCHAR(255),
        error_type VARCHAR(255),
        error_description VARCHAR(5000),
        error_value VARCHAR(5000),
        expected_format VARCHAR(1000),
        record_identifier VARCHAR(255),
        error_timestamp TIMESTAMP_NTZ,
        severity_level VARCHAR(50),
        resolution_status VARCHAR(100),
        resolved_by VARCHAR(255),
        resolution_timestamp TIMESTAMP_NTZ,
        load_date DATE,
        update_date DATE,
        source_system VARCHAR(255)
    )"
) }}

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
FROM (
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
) initial_record
