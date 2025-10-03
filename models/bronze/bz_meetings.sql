{{config(
  materialized = 'table'
)}}

SELECT
  meeting_id,
  host_id,
  meeting_topic,
  start_time,
  end_time,
  duration_minutes,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'meetings') }}
