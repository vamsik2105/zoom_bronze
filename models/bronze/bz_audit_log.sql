-- Audit log model for tracking bronze layer transformations
-- This model must be created first before other bronze models

{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_audit_log', CURRENT_TIMESTAMP(), 'dbt', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_audit_log', CURRENT_TIMESTAMP(), 'dbt', DATEDIFF('second', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'bz_audit_log' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- Create the audit log table structure
SELECT 
    1 as record_id,
    CAST('INITIAL_LOAD' AS VARCHAR(255)) as source_table,
    CURRENT_TIMESTAMP() as load_timestamp,
    'dbt' as processed_by,
    0 as processing_time,
    'INITIALIZED' as status
WHERE FALSE -- This ensures no actual data is inserted during initial creation