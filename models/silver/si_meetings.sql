{{ config(materialized='table') }}

WITH bronze_meetings AS (
    SELECT * FROM {{ source('bronze', 'bz_meetings') }}
),

users_ref AS (
    SELECT user_id FROM {{ ref('si_users') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bm.*,
        -- Quality score calculation
        CASE 
            WHEN bm.meeting_id IS NULL THEN 0
            WHEN bm.host_id IS NULL THEN 0.2
            WHEN bm.start_time IS NULL OR bm.end_time IS NULL THEN 0.3
            WHEN bm.end_time <= bm.start_time THEN 0.4
            WHEN bm.duration_minutes IS NULL OR bm.duration_minutes <= 0 OR bm.duration_minutes > 1440 THEN 0.5
            WHEN u.user_id IS NULL THEN 0.6  -- Host doesn't exist in users
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bm.meeting_id IS NULL OR bm.host_id IS NULL OR bm.start_time IS NULL OR bm.end_time IS NULL THEN 'error'
            WHEN bm.end_time <= bm.start_time THEN 'error'
            WHEN bm.duration_minutes IS NULL OR bm.duration_minutes <= 0 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_meetings bm
    LEFT JOIN users_ref u ON bm.host_id = u.user_id
),

-- Clean and transform data
cleaned_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        TRIM(meeting_topic) AS meeting_topic,
        start_time,
        end_time,
        duration_minutes,
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
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM cleaned_meetings
