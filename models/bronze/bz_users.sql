{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_users') }}",
  post_hook="{{ log_model_completion('bz_users', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw users data to bronze layer
SELECT
  user_id,
  user_name,
  email,
  company,
  plan_type,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'users') }}
