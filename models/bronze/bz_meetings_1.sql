{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_meetings', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_meetings transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_meetings', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_meetings transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for meetings
WITH source_meetings AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'meetings') }}
),

-- Data quality checks and transformations
cleaned_meetings AS (
    SELECT 
        COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
        COALESCE(host_id, 'UNKNOWN') as host_id,
        COALESCE(meeting_topic, 'UNKNOWN') as meeting_topic,
        start_time,
        end_time,
        COALESCE(duration_minutes, 0) as duration_minutes,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_meetings
    WHERE meeting_id IS NOT NULL
)

SELECT * FROM cleaned_meetings
