{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
    SELECT
      'billing_events' AS source_table,
      CURRENT_TIMESTAMP() AS load_timestamp,
      CURRENT_USER() AS processed_by,
      'STARTED' AS status
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """],
  post_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT
      'billing_events' AS source_table,
      CURRENT_TIMESTAMP() AS load_timestamp,
      CURRENT_USER() AS processed_by,
      DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'billing_events' AND status = 'STARTED'), CURRENT_TIMESTAMP()) AS processing_time,
      'COMPLETED' AS status
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """]
)}}

-- Transform raw billing_events data to bronze layer
SELECT
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'billing_events') }}
