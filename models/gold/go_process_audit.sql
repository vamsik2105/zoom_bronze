{{ config(
    materialized='table'
) }}

SELECT 
    'INIT'::VARCHAR(255) as process_id,
    'GOLD_FACT_LOAD'::VARCHAR(255) as process_name,
    'SILVER_TABLES'::VARCHAR(255) as source_table,
    'GOLD_FACTS'::VARCHAR(255) as target_table,
    'INITIALIZED'::VARCHAR(50) as process_status,
    CURRENT_TIMESTAMP() as start_time,
    NULL::TIMESTAMP_NTZ as end_time,
    0 as records_processed,
    NULL::VARCHAR(500) as error_message,
    CURRENT_DATE() as load_date
WHERE 1=0
