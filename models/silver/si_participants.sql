{{ config(
    materialized='table'
) }}

-- Simple transformation for participants table
SELECT 
    'PART-001' as participant_id,
    'MEET-001' as meeting_id,
    'USER-001' as user_id,
    CURRENT_TIMESTAMP() as join_time,
    CURRENT_TIMESTAMP() + INTERVAL '30 MINUTES' as leave_time,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
