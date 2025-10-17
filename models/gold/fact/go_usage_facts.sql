{{ config(
    materialized='table',
    cluster_by=['usage_date', 'organization_id']
) }}

SELECT 
    CONCAT('UF_', MD5(user_id || usage_date::STRING)) as usage_fact_id,
    user_id,
    'INDIVIDUAL' as organization_id,
    usage_date,
    0 as meeting_count,
    0 as total_meeting_minutes,
    0 as webinar_count,
    0 as total_webinar_minutes,
    CASE WHEN feature_name = 'Recording' THEN usage_count * 0.1 ELSE 0 END as recording_storage_gb,
    usage_count as feature_usage_count,
    0 as unique_participants_hosted,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM ZOOM.SILVER.si_feature_usage
WHERE record_status = 'ACTIVE'
