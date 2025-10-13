{{ config(
    materialized='table'
) }}

-- Simple transformation for billing events table
SELECT 
    'BILL-001' as event_id,
    'USER-001' as user_id,
    'Subscription Fee' as event_type,
    29.99 as amount,
    CURRENT_DATE() as event_date,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
