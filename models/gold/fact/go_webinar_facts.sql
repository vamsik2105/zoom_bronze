{{ config(
    materialized='table',
    cluster_by=['load_date', 'webinar_id']
) }}

WITH silver_webinars AS (
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        load_timestamp,
        update_timestamp,
        source_system,
        load_date,
        update_date,
        data_quality_score,
        record_status
    FROM SILVER.si_webinars
    WHERE record_status = 'ACTIVE'
),

silver_participants AS (
    SELECT 
        meeting_id,
        participant_id,
        user_id,
        join_time,
        leave_time
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
),

silver_feature_usage AS (
    SELECT 
        meeting_id,
        feature_name,
        usage_count
    FROM SILVER.si_feature_usage
    WHERE record_status = 'ACTIVE'
),

webinar_attendance AS (
    SELECT 
        sw.webinar_id,
        COUNT(DISTINCT sp.participant_id) as actual_attendees,
        COUNT(DISTINCT sp.participant_id) as max_concurrent_attendees
    FROM silver_webinars sw
    LEFT JOIN silver_participants sp ON sw.webinar_id = sp.meeting_id
    GROUP BY sw.webinar_id
),

webinar_features AS (
    SELECT 
        sw.webinar_id,
        SUM(CASE WHEN sfu.feature_name = 'Q&A' THEN sfu.usage_count ELSE 0 END) as qa_questions_count,
        SUM(CASE WHEN sfu.feature_name = 'Polling' THEN sfu.usage_count ELSE 0 END) as poll_responses_count
    FROM silver_webinars sw
    LEFT JOIN silver_feature_usage sfu ON sw.webinar_id = sfu.meeting_id
    GROUP BY sw.webinar_id
)

SELECT 
    CONCAT('WF_', sw.webinar_id, '_', CURRENT_TIMESTAMP()::STRING) as webinar_fact_id,
    sw.webinar_id,
    sw.host_id,
    TRIM(COALESCE(sw.webinar_topic, 'No Topic Specified')) as webinar_topic,
    sw.start_time as start_time,
    sw.end_time as end_time,
    DATEDIFF('minute', sw.start_time, sw.end_time) as duration_minutes,
    COALESCE(sw.registrants, 0) as registrants_count,
    COALESCE(wa.actual_attendees, 0) as actual_attendees,
    CASE WHEN COALESCE(sw.registrants, 0) > 0 
         THEN ROUND((COALESCE(wa.actual_attendees, 0)::FLOAT / sw.registrants) * 100, 2)
         ELSE 0 END as attendance_rate,
    COALESCE(wa.max_concurrent_attendees, 0) as max_concurrent_attendees,
    COALESCE(wf.qa_questions_count, 0) as qa_questions_count,
    COALESCE(wf.poll_responses_count, 0) as poll_responses_count,
    ROUND((COALESCE(wf.qa_questions_count, 0) * 0.4 + 
           COALESCE(wf.poll_responses_count, 0) * 0.3 + 
           CASE WHEN COALESCE(sw.registrants, 0) > 0 
                THEN (COALESCE(wa.actual_attendees, 0)::FLOAT / sw.registrants) * 100 * 0.3
                ELSE 0 END) / 10, 2) as engagement_score,
    CASE WHEN DATEDIFF('minute', sw.start_time, sw.end_time) > 120 THEN 'Long Form'
         WHEN DATEDIFF('minute', sw.start_time, sw.end_time) > 60 THEN 'Standard'
         ELSE 'Short Form' END as event_category,
    sw.load_date,
    CURRENT_DATE() as update_date,
    sw.source_system
FROM silver_webinars sw
LEFT JOIN webinar_attendance wa ON sw.webinar_id = wa.webinar_id
LEFT JOIN webinar_features wf ON sw.webinar_id = wf.webinar_id
