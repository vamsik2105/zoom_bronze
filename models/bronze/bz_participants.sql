{{ config(
    materialized='table',
    pre_hook=[
      "{{ log_audit_start('bz_participants') }}"
    ],
    post_hook=[
      "{{ log_audit_end('bz_participants') }}"
    ]
) }}

-- Bronze layer transformation for participants table
-- This model performs a 1:1 mapping from raw to bronze layer
WITH source_data AS (
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
)

SELECT
    -- Direct mapping of fields from source to target
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    -- Metadata fields
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
FROM source_data
