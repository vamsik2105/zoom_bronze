{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM raw.participants
