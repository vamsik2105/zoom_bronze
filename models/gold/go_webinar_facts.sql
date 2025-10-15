{{ config(
    materialized='table'
) }}

SELECT 
    'WF_001' as webinar_fact_id,
    'WEBINAR_001' as webinar_id,
    'HOST_001' as host_id,
    'Sample Webinar' as webinar_topic,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    90 as duration_minutes,
    100 as registrants_count,
    75 as actual_attendees,
    75.0 as attendance_rate,
    75 as max_concurrent_attendees,
    5 as qa_questions_count,
    3 as poll_responses_count,
    6.8 as engagement_score,
    'Standard' as event_category,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
