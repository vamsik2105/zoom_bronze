{{ config(materialized='table') }}

WITH error_base AS (
    SELECT 
        'INIT' AS error_id,
        'INITIALIZATION' AS source_table,
        'INITIALIZATION' AS source_column,
        'INITIALIZATION' AS error_type,
        'INITIALIZATION' AS error_description,
        'INITIALIZATION' AS error_value,
        'INITIALIZATION' AS expected_format,
        'INITIALIZATION' AS record_identifier,
        CURRENT_TIMESTAMP() AS error_timestamp,
        'LOW' AS severity_level,
        'RESOLVED' AS resolution_status,
        'SYSTEM' AS resolved_by,
        CURRENT_TIMESTAMP() AS resolution_timestamp,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM' AS source_system
    WHERE 1=0  -- This ensures no rows are inserted during initial creation
)

SELECT 
    error_id::VARCHAR(255),
    source_table::VARCHAR(255),
    source_column::VARCHAR(255),
    error_type::VARCHAR(255),
    error_description::VARCHAR(1000),
    error_value::VARCHAR(1000),
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
