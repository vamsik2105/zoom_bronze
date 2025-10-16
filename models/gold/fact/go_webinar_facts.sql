{{ config(
    materialized='table'
) }}

-- Webinar Facts transformation from Silver to Gold
SELECT 
    'WF_' || webinar_id || '_' || CURRENT_TIMESTAMP()::STRING as webinar_fact_id,
    webinar_id,
    host_id,
    COALESCE(TRIM(webinar_topic), 'No Topic Specified') as webinar_topic,
    start_time,
    end_time,
    COALESCE(DATEDIFF('minute', start_time, end_time), 0) as duration_minutes,
    COALESCE(registrants, 0) as registrants_count,
    0 as actual_attendees,
    0.0 as attendance_rate,
    0 as max_concurrent_attendees,
    0 as qa_questions_count,
    0 as poll_responses_count,
    0.0 as engagement_score,
    CASE 
        WHEN COALESCE(DATEDIFF('minute', start_time, end_time), 0) > 120 THEN 'Long Form'
        WHEN COALESCE(DATEDIFF('minute', start_time, end_time), 0) > 60 THEN 'Standard'
        ELSE 'Short Form' 
    END as event_category,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM {{ source('silver', 'si_webinars') }}
WHERE record_status = 'ACTIVE'
