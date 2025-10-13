{{ config(materialized='table') }}
SELECT 1 as record_id, CAST('INITIAL_LOAD' AS VARCHAR(255)) as source_table, CURRENT_TIMESTAMP() as load_timestamp, 'dbt' as processed_by, 0 as processing_time, 'INITIALIZED' as status WHERE FALSE
