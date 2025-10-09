{{ config(materialized='table', tags=['bronze', 'audit']) }}

-- Create audit log table with explicit column definitions
SELECT 
    CAST(NULL AS VARCHAR(255)) AS source_table,
    CAST(NULL AS VARCHAR(50)) AS operation_type,
    CAST(NULL AS NUMBER) AS record_count,
    CAST(NULL AS VARCHAR(50)) AS process_status,
    CAST(NULL AS TIMESTAMP_NTZ) AS created_at,
    CAST(NULL AS TIMESTAMP_NTZ) AS updated_at
WHERE 1=0  -- This ensures no data is inserted, just creates the structure
