-- Bronze layer transformation for participants data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "{{ log_audit_start('bz_participants') }}",
    post_hook = "{{ log_audit_end('bz_participants', True) }}"
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
