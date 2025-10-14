{{ config(
    materialized='table'
) }}

SELECT 
    'summary_001' as summary_id,
    CURRENT_DATE() as summary_date,
    'ORG_001' as organization_id,
    0 as total_meetings,
    0 as total_meeting_minutes,
    0 as total_participants,
    0 as unique_hosts,
    0 as unique_participants,
    0.0 as average_meeting_duration,
    0.0 as average_participants_per_meeting,
    0 as meetings_with_recording,
    0.0 as recording_percentage,
    0.0 as average_quality_score,
    0.0 as average_engagement_score,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SILVER' as source_system
WHERE 1=0
