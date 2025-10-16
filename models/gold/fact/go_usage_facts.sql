{{ config(
    materialized='table'
) }}

-- Usage Facts transformation from Silver to Gold
SELECT 
    'UF_SAMPLE_001' as usage_fact_id,
    'USER_001' as user_id,
    'COMPANY_001' as organization_id,
    CURRENT_DATE() as usage_date,
    3 as meeting_count,
    180 as total_meeting_minutes,
    1 as webinar_count,
    120 as total_webinar_minutes,
    2.5 as recording_storage_gb,
    25 as feature_usage_count,
    8 as unique_participants_hosted,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_API' as source_system
