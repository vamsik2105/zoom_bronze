{{ config(
    materialized='table',
    cluster_by=['start_time', 'host_id']
) }}

SELECT 
    CONCAT('WF_', webinar_id, '_', CURRENT_TIMESTAMP()::STRING) as webinar_fact_id,
    webinar_id,
    host_id,
    TRIM(COALESCE(webinar_topic, 'No Topic Specified')) as webinar_topic,
    CONVERT_TIMEZONE('UTC', start_time) as start_time,
    CONVERT_TIMEZONE('UTC', end_time) as end_time,
    DATEDIFF('minute', start_time, end_time) as duration_minutes,
    COALESCE(registrants, 0) as registrants_count,
    0 as actual_attendees,
    0.0 as attendance_rate,
    0 as max_concurrent_attendees,
    0 as qa_questions_count,
    0 as poll_responses_count,
    0.0 as engagement_score,
    CASE 
        WHEN DATEDIFF('minute', start_time, end_time) > 120 THEN 'Long Form'
        WHEN DATEDIFF('minute', start_time, end_time) > 60 THEN 'Standard'
        ELSE 'Short Form'
    END as event_category,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM ZOOM.SILVER.si_webinars
WHERE record_status = 'ACTIVE'
