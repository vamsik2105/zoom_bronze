{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  webinar_id,
  host_id,
  webinar_topic,
  start_time,
  end_time,
  registrants,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM raw.webinars
