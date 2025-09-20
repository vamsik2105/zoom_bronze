{{ config(
    materialized='table',
    tags=['audit', 'bronze']
) }}

WITH audit_base AS (
    SELECT 
        CAST(NULL AS STRING) AS table_name,
        CAST(NULL AS TIMESTAMP) AS process_start_time,
        CAST(NULL AS TIMESTAMP) AS process_end_time,
        CAST(NULL AS STRING) AS status,
        CAST(NULL AS TIMESTAMP) AS created_at,
        CAST(NULL AS TIMESTAMP) AS updated_at
    WHERE 1=0  -- This ensures no rows are returned, just creates the structure
)

SELECT 
    table_name,
    process_start_time,
    process_end_time,
    status,
    created_at,
    updated_at
FROM audit_base