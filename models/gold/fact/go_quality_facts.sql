{{ config(
    materialized='table',
    cluster_by=['load_date', 'meeting_id']
) }}

WITH silver_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        data_quality_score,
        load_date,
        source_system
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
)

SELECT 
    CONCAT('QF_', sp.meeting_id, '_', sp.participant_id) as quality_fact_id,
    sp.meeting_id,
    sp.participant_id,
    CONCAT('DC_', sp.participant_id, '_', CURRENT_TIMESTAMP()::STRING) as device_connection_id,
    ROUND(sp.data_quality_score * 0.8, 2) as audio_quality_score,
    ROUND(sp.data_quality_score * 0.9, 2) as video_quality_score,
    ROUND(sp.data_quality_score, 2) as connection_stability_rating,
    CASE WHEN sp.data_quality_score > 8 THEN 50
         WHEN sp.data_quality_score > 6 THEN 100
         ELSE 200 END as latency_ms,
    CASE WHEN sp.data_quality_score > 8 THEN 0.01
         WHEN sp.data_quality_score > 6 THEN 0.05
         ELSE 0.1 END as packet_loss_rate,
    DATEDIFF('minute', sp.join_time, COALESCE(sp.leave_time, CURRENT_TIMESTAMP())) * 2 as bandwidth_utilization,
    CASE WHEN sp.data_quality_score > 8 THEN 25.0
         WHEN sp.data_quality_score > 6 THEN 50.0
         ELSE 75.0 END as cpu_usage_percentage,
    DATEDIFF('minute', sp.join_time, COALESCE(sp.leave_time, CURRENT_TIMESTAMP())) * 10 as memory_usage_mb,
    sp.load_date,
    CURRENT_DATE() as update_date,
    sp.source_system
FROM silver_participants sp
