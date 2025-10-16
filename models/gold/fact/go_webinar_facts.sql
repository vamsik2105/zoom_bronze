{{ config(
    materialized='table'
) }}

SELECT 
    webinar_id as webinar_fact_id,
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    0 as duration_minutes,
    registrants as registrants_count,
    0 as actual_attendees,
    0.0 as attendance_rate,
    0 as max_concurrent_attendees,
    0 as qa_questions_count,
    0 as poll_responses_count,
    0.0 as engagement_score,
    'Standard' as event_category,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_webinars
WHERE record_status = 'ACTIVE'
