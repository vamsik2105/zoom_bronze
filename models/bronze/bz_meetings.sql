{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_meetings') }}",
  post_hook="{{ log_model_completion('bz_meetings', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw meetings data to bronze layer
SELECT
  meeting_id,
  host_id,
  meeting_topic,
  start_time,
  end_time,
  duration_minutes,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'meetings') }}
