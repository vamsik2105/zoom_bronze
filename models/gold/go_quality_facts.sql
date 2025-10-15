{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date) VALUES (CONCAT('PROC_QF_', CURRENT_TIMESTAMP()::STRING), 'Quality Facts Processing', 'si_participants', 'go_quality_facts', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE process_name = 'Quality Facts Processing' AND process_status = 'STARTED'"
) }}

WITH participant_quality AS (
    SELECT 
        participant_id,
        meeting_id,
        join_time,
        leave_time,
        data_quality_score,
        load_date,
        source_system
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
)

SELECT 
    CONCAT('QF_', pq.meeting_id, '_', pq.participant_id) as quality_fact_id,
    pq.meeting_id,
    pq.participant_id,
    CONCAT('DC_', pq.participant_id, '_', CURRENT_TIMESTAMP()::STRING) as device_connection_id,
    ROUND(pq.data_quality_score * 0.8, 2) as audio_quality_score,
    ROUND(pq.data_quality_score * 0.9, 2) as video_quality_score,
    ROUND(pq.data_quality_score, 2) as connection_stability_rating,
    CASE WHEN pq.data_quality_score > 8 THEN 50
         WHEN pq.data_quality_score > 6 THEN 100
         ELSE 200 END as latency_ms,
    CASE WHEN pq.data_quality_score > 8 THEN 0.01
         WHEN pq.data_quality_score > 6 THEN 0.05
         ELSE 0.1 END as packet_loss_rate,
    DATEDIFF('minute', pq.join_time, pq.leave_time) * 2 as bandwidth_utilization,
    CASE WHEN pq.data_quality_score > 8 THEN 25.0
         WHEN pq.data_quality_score > 6 THEN 50.0
         ELSE 75.0 END as cpu_usage_percentage,
    DATEDIFF('minute', pq.join_time, pq.leave_time) * 10 as memory_usage_mb,
    pq.load_date,
    CURRENT_DATE() as update_date,
    pq.source_system
FROM participant_quality pq
