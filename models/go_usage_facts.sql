{{ config(
    materialized='table'
) }}

SELECT 
    usage_id as usage_fact_id,
    'USER_001' as user_id,
    'INDIVIDUAL' as organization_id,
    usage_date,
    1 as meeting_count,
    usage_count as total_meeting_minutes,
    0 as webinar_count,
    0 as total_webinar_minutes,
    0 as recording_storage_gb,
    usage_count as feature_usage_count,
    0 as unique_participants_hosted,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_feature_usage
LIMIT 100
