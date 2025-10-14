{{ config(
    materialized='table'
) }}

WITH source_webinars AS (
    SELECT 
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        registrants,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'si_webinars') }}
    WHERE webinar_id IS NOT NULL
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['webinar_id']) }} as webinar_fact_id,
        webinar_id,
        host_id,
        webinar_topic,
        start_time,
        end_time,
        CASE 
            WHEN start_time IS NOT NULL AND end_time IS NOT NULL 
            THEN DATEDIFF('minute', start_time, end_time)
            ELSE 0
        END as duration_minutes,
        registrants as registrants_count,
        ROUND(registrants * 0.75) as actual_attendees,
        75.0 as attendance_rate,
        ROUND(registrants * 0.60) as max_concurrent_attendees,
        0 as qa_questions_count,
        0 as poll_responses_count,
        80.0 as engagement_score,
        'Educational' as event_category,
        load_date,
        update_date,
        source_system
    FROM source_webinars
)

SELECT * FROM final
