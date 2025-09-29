{{ config(
    materialized='table',
    schema='bronze',
    pre_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_participants' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_participants', CURRENT_TIMESTAMP(), 'STARTED', 'Processing started for bz_participants')"
    ],
    post_hook=[
        "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, status, message) VALUES (MD5('bz_participants' || '-' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD HH24:MI:SS.FF')), 'bz_participants', CURRENT_TIMESTAMP(), 'COMPLETED', 'Processing completed for bz_participants')"
    ]
) }}

-- Source to Bronze transformation for Zoom participants
SELECT
    -- Primary fields
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    
    -- Metadata fields
    load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'participants') }}
