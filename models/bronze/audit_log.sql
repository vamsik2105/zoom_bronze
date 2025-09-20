{{ config(
    materialized='table',
    schema='bronze'
) }}

/*
    Audit Log Table for Bronze Layer Processing
    Purpose: Track all bronze layer transformations and their status
*/

SELECT 
    'CUSTOMER_DETAILS_BRZ' AS table_name,
    CURRENT_TIMESTAMP() AS process_start_time,
    NULL AS process_end_time,
    'INITIALIZED' AS status,
    '{{ run_started_at }}' AS dbt_run_timestamp,
    '{{ invocation_id }}' AS dbt_invocation_id
WHERE FALSE  -- This creates the table structure without inserting initial data
