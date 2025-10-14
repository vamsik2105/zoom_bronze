{{ config(
    materialized='view'
) }}

SELECT 
    m.meeting_id,
    m.meeting_topic,
    m.start_time,
    m.duration_minutes,
    COALESCE(pc.participant_count, 0) as participant_count,
    ROUND(COALESCE(m.data_quality_score, 0) * 0.8, 2) as engagement_score,
    ROUND(COALESCE(m.data_quality_score, 0), 2) as quality_score_avg,
    u.user_name as host_name,
    u.company as department_name,
    u.company as organization_name,
    MONTHNAME(m.start_time) as month_name,
    YEAR(m.start_time) as year_number
FROM {{ source('silver', 'si_meetings') }} m
LEFT JOIN {{ source('silver', 'si_users') }} u ON m.host_id = u.user_id
LEFT JOIN (
    SELECT 
        meeting_id,
        COUNT(participant_id) as participant_count
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
    GROUP BY meeting_id
) pc ON m.meeting_id = pc.meeting_id
WHERE m.record_status = 'ACTIVE'
    AND u.record_status = 'ACTIVE'
