{{config(
  materialized = 'table'
)}}

-- Transform raw participants data to bronze layer
SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'participants') }}
