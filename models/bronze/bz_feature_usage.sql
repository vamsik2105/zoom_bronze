{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_table_processing_start('feature_usage') }}",
  post_hook="{{ log_table_processing_complete('feature_usage') }}"
)}}

-- Transform raw feature_usage data to bronze layer
SELECT
  usage_id,
  meeting_id,
  feature_name,
  usage_count,
  usage_date,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'feature_usage') }}
