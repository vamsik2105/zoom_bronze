{{config(
  materialized = 'table',
  pre_hook="{{ log_model_start('bz_webinars') }}",
  post_hook="{{ log_model_completion('bz_webinars', adapter.get_relation(this.database, this.schema, this.name).get_row_count()) }}"
)}}

-- Transform raw webinars data to bronze layer
SELECT
  webinar_id,
  host_id,
  webinar_topic,
  start_time,
  end_time,
  registrants,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'webinars') }}
