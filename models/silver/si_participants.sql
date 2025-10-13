{{ config(materialized='table') }}

-- Silver Participants Table
WITH bronze_participants AS (
    SELECT *
    FROM {{ source('bronze', 'bz_participants') }}
),

valid_users AS (
    SELECT DISTINCT user_id FROM {{ ref('si_users') }}
),

valid_meetings AS (
    SELECT meeting_id, start_time, end_time FROM {{ ref('si_meetings') }}
),

data_quality_checks AS (
    SELECT 
        bp.*,
        vm.start_time as meeting_start_time,
        vm.end_time as meeting_end_time,
        
        -- Completeness checks
        CASE WHEN participant_id IS NULL THEN 1 ELSE 0 END as missing_participant_id,
        CASE WHEN meeting_id IS NULL THEN 1 ELSE 0 END as missing_meeting_id,
        CASE WHEN join_time IS NULL THEN 1 ELSE 0 END as missing_join_time,
        CASE WHEN leave_time IS NULL THEN 1 ELSE 0 END as missing_leave_time,
        
        -- Referential integrity
        CASE WHEN bp.user_id IS NOT NULL AND vu.user_id IS NULL THEN 1 ELSE 0 END as invalid_user_ref,
        CASE WHEN vm.meeting_id IS NULL THEN 1 ELSE 0 END as invalid_meeting_ref,
        
        -- Logical consistency
        CASE WHEN join_time IS NOT NULL AND leave_time IS NOT NULL AND leave_time <= join_time 
             THEN 1 ELSE 0 END as invalid_participation_time,
        CASE WHEN join_time IS NOT NULL AND vm.start_time IS NOT NULL AND join_time < vm.start_time 
             THEN 1 ELSE 0 END as join_before_meeting,
        CASE WHEN leave_time IS NOT NULL AND vm.end_time IS NOT NULL AND leave_time > vm.end_time 
             THEN 1 ELSE 0 END as leave_after_meeting,
        
        -- Calculate data quality score
        CASE 
            WHEN participant_id IS NULL OR meeting_id IS NULL OR join_time IS NULL OR leave_time IS NULL THEN 0.0
            WHEN vm.meeting_id IS NULL THEN 0.2
            WHEN leave_time <= join_time THEN 0.4
            WHEN join_time < vm.start_time OR leave_time > vm.end_time THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_participants bp
    LEFT JOIN valid_users vu ON bp.user_id = vu.user_id
    LEFT JOIN valid_meetings vm ON bp.meeting_id = vm.meeting_id
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
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    CASE 
        WHEN missing_participant_id = 1 OR missing_meeting_id = 1 OR missing_join_time = 1 
             OR missing_leave_time = 1 OR invalid_meeting_ref = 1 OR invalid_participation_time = 1
        THEN 'error'
        ELSE 'active'
    END as record_status
FROM data_quality_checks
WHERE CASE 
        WHEN missing_participant_id = 1 OR missing_meeting_id = 1 OR missing_join_time = 1 
             OR missing_leave_time = 1 OR invalid_meeting_ref = 1 OR invalid_participation_time = 1
        THEN 'error'
        ELSE 'active'
    END = 'active'
