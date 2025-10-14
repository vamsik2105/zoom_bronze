{{ config(
    materialized='view'
) }}

SELECT 
    'MEETING_001' as meeting_id,
    'Sample Meeting' as meeting_topic,
    CURRENT_TIMESTAMP() as start_time,
    60 as duration_minutes,
    5 as participant_count,
    4.0 as engagement_score,
    4.5 as quality_score_avg,
    'John Doe' as host_name,
    'Engineering' as department_name,
    'Acme Corp' as organization_name,
    'January' as month_name,
    2024 as year_number
WHERE 1=0
