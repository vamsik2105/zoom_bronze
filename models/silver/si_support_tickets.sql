{{ config(
    materialized='table'
) }}

-- Simple transformation for support tickets table
SELECT 
    'TICK-001' as ticket_id,
    'USER-001' as user_id,
    'Audio Issue' as ticket_type,
    'Open' as resolution_status,
    CURRENT_DATE() as open_date,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
