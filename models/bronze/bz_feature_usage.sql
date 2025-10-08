{{config(
  materialized = 'table'
)}}

-- Pre-hook to log the start of processing
{% set source_table = 'feature_usage' %}
{{ config(
  pre_hook="{{ log_audit_start('" ~ source_table ~ "') }}"
) }}

-- Post-hook to log the end of processing
{{ config(
  post_hook="{{ log_audit_end('" ~ source_table ~ "', 'SUCCESS') }}"
) }}

-- Transform raw feature_usage data to bronze layer
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
