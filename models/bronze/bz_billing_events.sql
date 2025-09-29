{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_billing_events') }}",
  post_hook="{{ log_model_completion('bz_billing_events', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw billing events data to bronze layer
SELECT
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'billing_events') }}
