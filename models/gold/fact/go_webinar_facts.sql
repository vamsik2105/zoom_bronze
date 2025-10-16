{{ config(
    materialized='table'
) }}

-- Webinar Facts transformation from Silver to Gold
SELECT 
    CONCAT('WF_', webinar_id, '_', REPLACE(CURRENT_TIMESTAMP()::STRING, ' ', '_')) AS webinar_fact_id,
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    DATEDIFF('minute', start_time, end_time) AS duration_minutes,
    registrants AS registrants_count,
    0 AS actual_attendees,
    0.0 AS attendance_rate,
    0 AS max_concurrent_attendees,
    0 AS qa_questions_count,
    0 AS poll_responses_count,
    0.0 AS engagement_score,
    CASE 
        WHEN DATEDIFF('minute', start_time, end_time) > 120 THEN 'Long Form'
        WHEN DATEDIFF('minute', start_time, end_time) > 60 THEN 'Standard'
        ELSE 'Short Form'
    END AS event_category,
    load_date,
    CURRENT_DATE() AS update_date,
    source_system
FROM SILVER.si_webinars
WHERE record_status = 'ACTIVE'
