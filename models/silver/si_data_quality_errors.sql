{{ config(materialized='table') }}

WITH error_base AS (
    SELECT 
        'init' as error_id,
        'initialization' as source_table,
        'init' as source_column,
        'INIT' as error_type,
        'Initialization record' as error_description,
        'N/A' as error_value,
        'N/A' as expected_format,
        'init' as record_identifier,
        CURRENT_TIMESTAMP() as error_timestamp,
        'LOW' as severity_level,
        'RESOLVED' as resolution_status,
        'SYSTEM' as resolved_by,
        CURRENT_TIMESTAMP() as resolution_timestamp,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'SYSTEM' as source_system
    WHERE 1=0  -- This ensures no initial records are created
)

SELECT 
    error_id::VARCHAR(255),
    source_table::VARCHAR(255),
    source_column::VARCHAR(255),
    error_type::VARCHAR(100),
    error_description::VARCHAR(1000),
    error_value::VARCHAR(500),
    expected_format::VARCHAR(500),
    record_identifier::VARCHAR(255),
    error_timestamp,
    severity_level::VARCHAR(50),
    resolution_status::VARCHAR(50),
    resolved_by::VARCHAR(255),
    resolution_timestamp,
    load_date,
    update_date,
    source_system::VARCHAR(255)
FROM error_base
