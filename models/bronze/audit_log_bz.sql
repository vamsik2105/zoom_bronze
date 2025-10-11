{{ config(
    materialized='table',
    tags=['audit', 'bronze']
) }}

-- Create audit log table structure based on the provided schema
SELECT
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS audit_id,
    'RAW' AS source_layer,
    'INITIAL' AS source_table,
    'BRONZE' AS target_layer,
    'INITIAL' AS target_table,
    'FULL' AS load_type,
    CURRENT_TIMESTAMP() AS load_start_time,
    CURRENT_TIMESTAMP() AS load_end_time,
    0 AS record_count_loaded,
    'SUCCESS' AS status,
    NULL AS error_message,
    '{{ invocation_id }}' AS run_id,
    CURRENT_USER() AS created_by,
    CURRENT_TIMESTAMP() AS created_at
WHERE 1=0  -- This ensures no records are inserted initially
