{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_participants', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_participants transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_participants', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_participants transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for participants
WITH source_participants AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'participants') }}
),

-- Data quality checks and transformations
cleaned_participants AS (
    SELECT 
        COALESCE(participant_id, 'UNKNOWN') as participant_id,
        COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
        COALESCE(user_id, 'UNKNOWN') as user_id,
        join_time,
        leave_time,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_participants
    WHERE participant_id IS NOT NULL
)

SELECT * FROM cleaned_participants
