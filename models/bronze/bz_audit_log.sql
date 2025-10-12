{{ config(
    materialized='table',
    schema='bronze',
    tags=['bronze', 'audit', 'infrastructure']
) }}

/*
    Bronze Audit Log Table
    
    Purpose: Track processing of all bronze models for monitoring and debugging
*/

SELECT 
    1 AS record_id,
    'INITIAL_SETUP' AS source_table,
    CURRENT_TIMESTAMP() AS load_timestamp,
    CURRENT_USER() AS processed_by,
    0 AS processing_time,
    'SUCCESS' AS status
