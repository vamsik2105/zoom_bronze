{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM raw.billing_events
