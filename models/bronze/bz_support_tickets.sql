{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
    SELECT
      'support_tickets' AS source_table,
      CURRENT_TIMESTAMP() AS load_timestamp,
      CURRENT_USER() AS processed_by,
      'STARTED' AS status
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """],
  post_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT
      'support_tickets' AS source_table,
      CURRENT_TIMESTAMP() AS load_timestamp,
      CURRENT_USER() AS processed_by,
      DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'support_tickets' AND status = 'STARTED'), CURRENT_TIMESTAMP()) AS processing_time,
      'COMPLETED' AS status
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """]
)}}

-- Transform raw support_tickets data to bronze layer
SELECT
  ticket_id,
  user_id,
  ticket_type,
  resolution_status,
  open_date,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'support_tickets') }}
