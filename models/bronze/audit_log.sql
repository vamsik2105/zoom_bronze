{{ config(
    materialized='table'
) }}

/*
    Audit Log Table for Bronze Layer Processing
    
    Purpose: Track all bronze layer transformations and their status
    This table must be created before any other bronze models
*/

SELECT 
    'INITIAL' AS table_name,
    'INITIALIZED' AS process_status,
    CURRENT_TIMESTAMP AS process_start_time,
    CURRENT_TIMESTAMP AS process_end_time,
    0 AS record_count,
    CURRENT_TIMESTAMP AS created_at
WHERE 1=0  -- This ensures the table structure is created but no initial records