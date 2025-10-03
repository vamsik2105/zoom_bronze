{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status) VALUES ('licenses', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')"
  ],
  post_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('licenses', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'licenses' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
  ]
)}}

SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'licenses') }}
