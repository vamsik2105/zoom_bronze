{{ config(
    materialized='table',
    cluster_by=['start_time', 'host_id']
) }}

-- Webinar Facts transformation from Silver to Gold
WITH webinar_base AS (
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
    FROM {{ source('silver', 'si_webinars') }}
    WHERE record_status = 'ACTIVE'
),

webinar_attendance AS (
    SELECT 
        meeting_id AS webinar_id,
        COUNT(DISTINCT participant_id) AS actual_attendees
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

webinar_features AS (
    SELECT 
        meeting_id AS webinar_id,
        SUM(CASE WHEN feature_name = 'Q&A' THEN usage_count ELSE 0 END) AS qa_questions_count,
        SUM(CASE WHEN feature_name = 'Polling' THEN usage_count ELSE 0 END) AS poll_responses_count
    FROM {{ source('silver', 'si_feature_usage') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
),

final_transform AS (
    SELECT 
        CONCAT('WF_', wb.webinar_id, '_', CURRENT_TIMESTAMP()::STRING) AS webinar_fact_id,
        wb.webinar_id,
        wb.host_id,
        TRIM(COALESCE(wb.webinar_topic, 'No Topic Specified')) AS webinar_topic,
        CONVERT_TIMEZONE('UTC', wb.start_time) AS start_time,
        CONVERT_TIMEZONE('UTC', wb.end_time) AS end_time,
        DATEDIFF('minute', wb.start_time, wb.end_time) AS duration_minutes,
        COALESCE(wb.registrants, 0) AS registrants_count,
        COALESCE(wa.actual_attendees, 0) AS actual_attendees,
        CASE 
            WHEN COALESCE(wb.registrants, 0) > 0 
            THEN (COALESCE(wa.actual_attendees, 0)::FLOAT / wb.registrants) * 100 
            ELSE 0 
        END AS attendance_rate,
        COALESCE(wa.actual_attendees, 0) AS max_concurrent_attendees,
        COALESCE(wf.qa_questions_count, 0) AS qa_questions_count,
        COALESCE(wf.poll_responses_count, 0) AS poll_responses_count,
        ROUND(
            (COALESCE(wf.qa_questions_count, 0) * 0.4 + 
             COALESCE(wf.poll_responses_count, 0) * 0.3 + 
             CASE WHEN COALESCE(wb.registrants, 0) > 0 
                  THEN (COALESCE(wa.actual_attendees, 0)::FLOAT / wb.registrants) * 100 * 0.3
                  ELSE 0 END) / 10, 2
        ) AS engagement_score,
        CASE 
            WHEN DATEDIFF('minute', wb.start_time, wb.end_time) > 120 THEN 'Long Form'
            WHEN DATEDIFF('minute', wb.start_time, wb.end_time) > 60 THEN 'Standard'
            ELSE 'Short Form'
        END AS event_category,
        wb.load_date,
        CURRENT_DATE() AS update_date,
        wb.source_system
    FROM webinar_base wb
    LEFT JOIN webinar_attendance wa ON wb.webinar_id = wa.webinar_id
    LEFT JOIN webinar_features wf ON wb.webinar_id = wf.webinar_id
)

SELECT * FROM final_transform
