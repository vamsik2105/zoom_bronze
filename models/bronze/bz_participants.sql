{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status) VALUES ('participants', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')"
  ],
  post_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('participants', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'participants' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
  ]
)}}

SELECT
  participant_id,
  meeting_id,
  user_id,
  join_time,
  leave_time,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'participants') }}
