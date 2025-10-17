{{ config(
    materialized='table',
    cluster_by=['start_time', 'host_id']
) }}

WITH webinar_base AS (
    SELECT 
        w.webinar_id,
        w.host_id,
        w.webinar_topic,
        w.start_time,
        w.end_time,
        w.registrants,
        w.load_date,
        w.source_system
    FROM {{ source('silver', 'si_webinars') }} w
    WHERE w.record_status = 'ACTIVE'
),

webinar_attendees AS (
    SELECT 
        p.meeting_id as webinar_id,
        COUNT(DISTINCT p.participant_id) as actual_attendees
    FROM {{ source('silver', 'si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
    GROUP BY p.meeting_id
),

webinar_features AS (
    SELECT 
        f.meeting_id as webinar_id,
        SUM(CASE WHEN f.feature_name = 'Q&A' THEN f.usage_count ELSE 0 END) as qa_questions_count,
        SUM(CASE WHEN f.feature_name = 'Polling' THEN f.usage_count ELSE 0 END) as poll_responses_count
    FROM {{ source('silver', 'si_feature_usage') }} f
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.meeting_id
)

SELECT 
    CONCAT('WF_', wb.webinar_id, '_', CURRENT_TIMESTAMP()::STRING) as webinar_fact_id,
    wb.webinar_id,
    wb.host_id,
    TRIM(COALESCE(wb.webinar_topic, 'No Topic Specified')) as webinar_topic,
    CONVERT_TIMEZONE('UTC', wb.start_time) as start_time,
    CONVERT_TIMEZONE('UTC', wb.end_time) as end_time,
    DATEDIFF('minute', wb.start_time, wb.end_time) as duration_minutes,
    COALESCE(wb.registrants, 0) as registrants_count,
    COALESCE(wa.actual_attendees, 0) as actual_attendees,
    CASE 
        WHEN wb.registrants > 0 THEN ROUND((wa.actual_attendees::FLOAT / wb.registrants) * 100, 2)
        ELSE 0 
    END as attendance_rate,
    COALESCE(wa.actual_attendees, 0) as max_concurrent_attendees,
    COALESCE(wf.qa_questions_count, 0) as qa_questions_count,
    COALESCE(wf.poll_responses_count, 0) as poll_responses_count,
    ROUND((COALESCE(wf.qa_questions_count, 0) * 0.4 + COALESCE(wf.poll_responses_count, 0) * 0.3 + COALESCE(wa.actual_attendees, 0) * 0.3) / 10, 2) as engagement_score,
    CASE 
        WHEN DATEDIFF('minute', wb.start_time, wb.end_time) > 120 THEN 'Long Form'
        WHEN DATEDIFF('minute', wb.start_time, wb.end_time) > 60 THEN 'Standard'
        ELSE 'Short Form'
    END as event_category,
    wb.load_date,
    CURRENT_DATE() as update_date,
    wb.source_system
FROM webinar_base wb
LEFT JOIN webinar_attendees wa ON wb.webinar_id = wa.webinar_id
LEFT JOIN webinar_features wf ON wb.webinar_id = wf.webinar_id
