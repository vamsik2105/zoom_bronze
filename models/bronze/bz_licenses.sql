{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM raw.licenses
