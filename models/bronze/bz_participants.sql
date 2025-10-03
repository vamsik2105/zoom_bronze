{{config(
  materialized = 'table'
)}}

SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'participants') }}
