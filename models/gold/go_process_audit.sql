{{ config(
    materialized='table'
) }}

SELECT 
    'INIT' as process_id,
    'GOLD_FACT_LOAD' as process_name,
    'SILVER_TABLES' as source_table,
    'GOLD_FACTS' as target_table,
    'INITIALIZED' as process_status,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    0 as records_processed,
    'Initial setup' as error_message,
    CURRENT_DATE() as load_date
