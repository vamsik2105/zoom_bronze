{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_participants') }}",
  post_hook="{{ log_model_completion('bz_participants', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw participants data to bronze layer
SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'participants') }}
