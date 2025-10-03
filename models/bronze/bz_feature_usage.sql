{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  usage_id,
  meeting_id,
  feature_name,
  usage_count,
  usage_date,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM raw.feature_usage
