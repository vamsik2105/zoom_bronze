{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_table_processing_start('licenses') }}",
  post_hook="{{ log_table_processing_complete('licenses') }}"
)}}

-- Transform raw licenses data to bronze layer
SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'licenses') }}
