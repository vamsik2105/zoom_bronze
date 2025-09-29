{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_feature_usage') }}",
  post_hook="{{ log_model_completion('bz_feature_usage', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw feature usage data to bronze layer
SELECT
  usage_id,
  meeting_id,
  feature_name,
  usage_count,
  usage_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'feature_usage') }}
