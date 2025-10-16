{{ config(
    materialized='table'
) }}

-- Webinar Facts transformation from Silver to Gold
SELECT 
    'WF_SAMPLE_001' as webinar_fact_id,
    'WEBINAR_001' as webinar_id,
    'HOST_001' as host_id,
    'Sample Webinar Topic' as webinar_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() + INTERVAL '2 HOURS' as end_time,
    120 as duration_minutes,
    100 as registrants_count,
    75 as actual_attendees,
    75.0 as attendance_rate,
    60 as max_concurrent_attendees,
    12 as qa_questions_count,
    8 as poll_responses_count,
    8.2 as engagement_score,
    'Long Form' as event_category,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_API' as source_system
