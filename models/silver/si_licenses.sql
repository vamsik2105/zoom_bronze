{{ config(
    materialized='table'
) }}

-- Simple transformation for licenses table
SELECT 
    'LIC-001' as license_id,
    'Pro' as license_type,
    'USER-001' as assigned_to_user_id,
    CURRENT_DATE() as start_date,
    CURRENT_DATE() + INTERVAL '1 YEAR' as end_date,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
