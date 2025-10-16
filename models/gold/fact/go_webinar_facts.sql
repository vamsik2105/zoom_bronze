{{ config(
    materialized='table',
    cluster_by=['load_date', 'webinar_id'],
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message) VALUES (CONCAT('WF_', CURRENT_TIMESTAMP()::STRING), 'go_webinar_facts_load', 'si_webinars', 'go_webinar_facts', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL)",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE process_name = 'go_webinar_facts_load' AND process_status = 'STARTED'"
) }}

WITH webinar_base AS (
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        load_date,
        source_system
    FROM {{ ref('si_webinars') }}
    WHERE record_status = 'ACTIVE'
),

webinar_attendance AS (
    SELECT 
        p.meeting_id as webinar_id,
        COUNT(DISTINCT p.participant_id) as actual_attendees
    FROM {{ ref('si_participants') }} p
    WHERE p.record_status = 'ACTIVE'
    GROUP BY p.meeting_id
),

webinar_features AS (
    SELECT 
        f.meeting_id as webinar_id,
        SUM(CASE WHEN f.feature_name = 'Q&A' THEN f.usage_count ELSE 0 END) as qa_questions_count,
        SUM(CASE WHEN f.feature_name = 'Polling' THEN f.usage_count ELSE 0 END) as poll_responses_count
    FROM {{ ref('si_feature_usage') }} f
    WHERE f.record_status = 'ACTIVE'
    GROUP BY f.meeting_id
),

final_webinar_facts AS (
    SELECT 
        CONCAT('WF_', w.webinar_id, '_', CURRENT_TIMESTAMP()::STRING) as webinar_fact_id,
        w.webinar_id,
        w.host_id,
        TRIM(COALESCE(w.webinar_topic, 'No Topic Specified')) as webinar_topic,
        CONVERT_TIMEZONE('UTC', w.start_time) as start_time,
        CONVERT_TIMEZONE('UTC', w.end_time) as end_time,
        DATEDIFF('minute', w.start_time, w.end_time) as duration_minutes,
        COALESCE(w.registrants, 0) as registrants_count,
        COALESCE(wa.actual_attendees, 0) as actual_attendees,
        CASE 
            WHEN w.registrants > 0 THEN (wa.actual_attendees::FLOAT / w.registrants) * 100 
            ELSE 0 
        END as attendance_rate,
        COALESCE(wa.actual_attendees, 0) as max_concurrent_attendees,
        COALESCE(wf.qa_questions_count, 0) as qa_questions_count,
        COALESCE(wf.poll_responses_count, 0) as poll_responses_count,
        ROUND((COALESCE(wf.qa_questions_count, 0) * 0.4 + COALESCE(wf.poll_responses_count, 0) * 0.3 + 
               CASE WHEN w.registrants > 0 THEN (wa.actual_attendees::FLOAT / w.registrants) * 100 ELSE 0 END * 0.3) / 10, 2) as engagement_score,
        CASE 
            WHEN DATEDIFF('minute', w.start_time, w.end_time) > 120 THEN 'Long Form'
            WHEN DATEDIFF('minute', w.start_time, w.end_time) > 60 THEN 'Standard'
            ELSE 'Short Form'
        END as event_category,
        w.load_date,
        CURRENT_DATE() as update_date,
        w.source_system
    FROM webinar_base w
    LEFT JOIN webinar_attendance wa ON w.webinar_id = wa.webinar_id
    LEFT JOIN webinar_features wf ON w.webinar_id = wf.webinar_id
)

SELECT * FROM final_webinar_facts
