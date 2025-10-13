{{ config(materialized='table') }}

WITH bronze_participants AS (
    SELECT * FROM {{ source('bronze', 'bz_participants') }}
),

users_ref AS (
    SELECT user_id FROM {{ ref('si_users') }}
),

meetings_ref AS (
    SELECT meeting_id, start_time, end_time FROM {{ ref('si_meetings') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bp.*,
        m.start_time AS meeting_start_time,
        m.end_time AS meeting_end_time,
        -- Quality score calculation
        CASE 
            WHEN bp.participant_id IS NULL THEN 0
            WHEN bp.meeting_id IS NULL THEN 0.2
            WHEN bp.join_time IS NULL OR bp.leave_time IS NULL THEN 0.3
            WHEN bp.leave_time <= bp.join_time THEN 0.4
            WHEN m.meeting_id IS NULL THEN 0.5  -- Meeting doesn't exist
            WHEN bp.user_id IS NOT NULL AND u.user_id IS NULL THEN 0.6  -- User doesn't exist
            WHEN bp.join_time < m.start_time OR bp.leave_time > m.end_time THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bp.participant_id IS NULL OR bp.meeting_id IS NULL THEN 'error'
            WHEN bp.join_time IS NULL OR bp.leave_time IS NULL THEN 'error'
            WHEN bp.leave_time <= bp.join_time THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_participants bp
    LEFT JOIN users_ref u ON bp.user_id = u.user_id
    LEFT JOIN meetings_ref m ON bp.meeting_id = m.meeting_id
),

-- Clean and transform data
cleaned_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM dq_checks
    WHERE record_status = 'active'
)

SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM cleaned_participants
