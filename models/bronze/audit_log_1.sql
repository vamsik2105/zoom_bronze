{{ config(
    materialized='table',
    pre_hook="",
    post_hook=""
) }}

-- Audit log table for tracking bronze layer processes
SELECT 
    'audit_log' as table_name,
    CURRENT_TIMESTAMP as process_start_time,
    CURRENT_TIMESTAMP as process_end_time,
    'SUCCESS' as status,
    'Audit log initialized' as message,
    CURRENT_TIMESTAMP as created_at
WHERE FALSE -- This ensures no actual data is inserted during model creation
