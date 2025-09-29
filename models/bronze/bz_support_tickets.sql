{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_support_tickets') }}",
  post_hook="{{ log_model_completion('bz_support_tickets', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw support tickets data to bronze layer
SELECT
  ticket_id,
  user_id,
  ticket_type,
  resolution_status,
  open_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'support_tickets') }}
