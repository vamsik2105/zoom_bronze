{{ config(
    materialized='table'
) }}

SELECT 
    'WEBINAR_001' AS webinar_fact_id,
    'W001' AS webinar_id,
    'U001' AS host_id,
    'Sample Webinar' AS webinar_topic,
    '2024-01-01 14:00:00'::timestamp AS start_time,
    '2024-01-01 15:00:00'::timestamp AS end_time,
    60 AS duration_minutes,
    100 AS registrants_count,
    75 AS actual_attendees,
    75.0 AS attendance_rate,
    60 AS max_concurrent_attendees,
    5 AS qa_questions_count,
    15 AS poll_responses_count,
    4.0 AS engagement_score,
    'Business' AS event_category,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SILVER' AS source_system
