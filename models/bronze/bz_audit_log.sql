{{ config(
    materialized='table'
) }}

SELECT
    1 as record_id,
    'initial_setup' as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'COMPLETED' as status
WHERE FALSE
