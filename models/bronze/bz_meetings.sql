{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_meetings' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_meetings', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_meetings')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_meetings' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_meetings', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_meetings')"
    ]
) }}

-- Source to Bronze transformation for Zoom meetings
SELECT
    -- Primary fields
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'meetings') }}
