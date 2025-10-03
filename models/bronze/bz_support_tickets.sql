{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  ticket_id,
  user_id,
  ticket_type,
  resolution_status,
  open_date,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM raw.support_tickets
