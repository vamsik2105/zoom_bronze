{{ config(
    materialized='table'
) }}

WITH silver_webinars AS (
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        source_system,
        load_date
    FROM SILVER.si_webinars
    WHERE record_status = 'ACTIVE'
)

SELECT 
    CONCAT('WF_', sw.webinar_id) as webinar_fact_id,
    sw.webinar_id,
    sw.host_id,
    COALESCE(sw.webinar_topic, 'No Topic Specified') as webinar_topic,
    sw.start_time,
    sw.end_time,
    DATEDIFF('minute', sw.start_time, sw.end_time) as duration_minutes,
    COALESCE(sw.registrants, 0) as registrants_count,
    0 as actual_attendees,
    0 as attendance_rate,
    0 as max_concurrent_attendees,
    0 as qa_questions_count,
    0 as poll_responses_count,
    0 as engagement_score,
    CASE WHEN DATEDIFF('minute', sw.start_time, sw.end_time) > 120 THEN 'Long Form'
         WHEN DATEDIFF('minute', sw.start_time, sw.end_time) > 60 THEN 'Standard'
         ELSE 'Short Form' END as event_category,
    sw.load_date,
    CURRENT_DATE() as update_date,
    sw.source_system
FROM silver_webinars sw
