{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_licenses') }}",
  post_hook="{{ log_model_completion('bz_licenses', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw licenses data to bronze layer
SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'licenses') }}
