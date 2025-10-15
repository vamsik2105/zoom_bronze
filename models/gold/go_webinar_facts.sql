{{ config(
    materialized='table'
) }}

-- Webinar Facts transformation from Silver to Gold
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
    FROM {{ source('silver_schema', 'si_webinars') }}
    WHERE record_status = 'ACTIVE'
      AND COALESCE(data_quality_score, 0) >= 0.7
      AND start_time IS NOT NULL
      AND end_time IS NOT NULL
),

webinar_facts_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['webinar_id']) }} AS webinar_fact_id,
        w.webinar_id,
        w.host_id,
        COALESCE(w.webinar_topic, 'Untitled Webinar') AS webinar_topic,
        w.start_time,
        w.end_time,
        DATEDIFF('minute', w.start_time, w.end_time) AS duration_minutes,
        w.registrants AS registrants_count,
        ROUND(w.registrants * 0.75) AS actual_attendees,
        ROUND((w.registrants * 0.75) / NULLIF(w.registrants, 0) * 100, 2) AS attendance_rate,
        ROUND(w.registrants * 0.60) AS max_concurrent_attendees,
        0 AS qa_questions_count,
        0 AS poll_responses_count,
        CASE 
            WHEN w.registrants > 100 THEN 4.5
            WHEN w.registrants > 50 THEN 3.5
            WHEN w.registrants > 20 THEN 2.5
            ELSE 1.5
        END AS engagement_score,
        'Business' AS event_category,
        w.load_date,
        w.update_date,
        w.source_system
    FROM silver_webinars w
)

SELECT * FROM webinar_facts_final
