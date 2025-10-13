{{ config(
    materialized='table'
) }}

-- Simple transformation for meetings table
SELECT 
    'MEET-001' as meeting_id,
    'USER-001' as host_id,
    'Test Meeting' as meeting_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() + INTERVAL '1 HOUR' as end_time,
    60 as duration_minutes,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
