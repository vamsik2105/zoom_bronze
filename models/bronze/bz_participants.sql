-- Bronze layer transformation for participants data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_participants', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, 'STARTED')",
    post_hook = "INSERT INTO {{ target.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_participants', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, 'SUCCESS')"
) }}

SELECT
    -- Direct 1:1 mapping from source
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'participants') }}
