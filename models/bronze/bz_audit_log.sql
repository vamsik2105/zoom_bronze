{{ config(
    materialized='table',
    schema='bronze',
    tags=['bronze', 'audit', 'infrastructure']
) }}

/*
    Bronze Audit Log Table
    
    Purpose: Track processing of all bronze models for monitoring and debugging
    Schema: BRONZE
    Table: bz_audit_log
    
    This model creates the foundational audit logging table that will be used
    to track the execution status, timing, and metadata for all bronze layer
    data processing operations.
    
    Dependencies: None (this should run first)
    Downstream: Referenced by all bronze models for audit logging
*/

SELECT 
    -- Primary key with auto-increment
    1 AS record_id,
    
    -- Source table name - explicitly sized to prevent truncation
    CAST('INITIAL_SETUP' AS VARCHAR(255)) AS source_table,
    
    -- Timestamp when the record was loaded (no timezone)
    CURRENT_TIMESTAMP() AS load_timestamp,
    
    -- User or process that performed the load
    CURRENT_USER() AS processed_by,
    
    -- Processing time in seconds or milliseconds
    0 AS processing_time,
    
    -- Status of the processing (SUCCESS, FAILED, IN_PROGRESS, etc.)
    CAST('SUCCESS' AS VARCHAR(50)) AS status
    
WHERE 1=0  -- This ensures no data is inserted, only structure is created
