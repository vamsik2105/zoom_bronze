{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status) VALUES ('feature_usage', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')"
  ],
  post_hook=[
    "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('feature_usage', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'feature_usage' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
  ]
)}}

SELECT
  usage_id,
  meeting_id,
  feature_name,
  usage_count,
  usage_date,
  load_timestamp,
  update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'feature_usage') }}
