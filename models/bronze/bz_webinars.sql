{{config(
  materialized = 'incremental',
  pre_hook=[
    "{% if target.table != 'bz_audit_log' %}
      INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
      VALUES ('webinars', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')
    {% endif %}"
  ],
  post_hook=[
    "{% if target.table != 'bz_audit_log' %}
      INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
      VALUES ('webinars', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'webinars' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')
    {% endif %}"
  ]
)}}

SELECT
  webinar_id,
  host_id,
  webinar_topic,
  start_time,
  end_time,
  registrants,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'webinars') }}
