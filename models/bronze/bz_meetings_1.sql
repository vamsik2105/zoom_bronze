{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, status, message, created_at) SELECT 'bz_meetings', CURRENT_TIMESTAMP, 'STARTED', 'Processing bz_meetings transformation', CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, status, message, created_at) SELECT 'bz_meetings', CURRENT_TIMESTAMP, 'SUCCESS', 'Completed bz_meetings transformation', CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for meetings
WITH source_data AS (
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

cleaned_data AS (
    SELECT 
        -- Direct 1-to-1 mapping from raw to bronze
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        -- Metadata columns with current timestamp
        CURRENT_TIMESTAMP as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
    WHERE meeting_id IS NOT NULL -- Basic data quality check
)

SELECT * FROM cleaned_data
