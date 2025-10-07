{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook="{{ log_audit_start('bz_feature_usage') }}",
  post_hook="{{ log_audit_end('bz_feature_usage') }}"
)}}

-- Transform raw feature usage data to bronze layer
SELECT
  usage_id,
  meeting_id,
  feature_name,
  usage_count,
  usage_date,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'feature_usage') }}
