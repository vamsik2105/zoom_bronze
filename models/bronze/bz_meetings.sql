{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status) VALUES ('meetings', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')"
  ],
  post_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('meetings', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'meetings' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
  ]
)}}

SELECT
  meeting_id,
  host_id,
  meeting_topic,
  start_time,
  end_time,
  duration_minutes,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'meetings') }}
