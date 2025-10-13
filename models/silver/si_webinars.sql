{{ config(
    materialized='table'
) }}

-- Simple transformation for webinars table
SELECT 
    'WEB-001' as webinar_id,
    'USER-001' as host_id,
    'Test Webinar' as webinar_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() + INTERVAL '2 HOURS' as end_time,
    100 as registrants,
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'SYSTEM' as source_system,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    1.0 as data_quality_score,
    'active' as record_status
WHERE FALSE -- This ensures no initial record is created
