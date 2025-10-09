{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
    SELECT
      'webinars' AS source_table,
      CURRENT_TIMESTAMP() AS load_timestamp,
      CURRENT_USER() AS processed_by,
      'STARTED' AS status
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """],
  post_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
    SELECT
      'webinars' AS source_table,
      CURRENT_TIMESTAMP() AS load_timestamp,
      CURRENT_USER() AS processed_by,
      DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'webinars' AND status = 'STARTED'), CURRENT_TIMESTAMP()) AS processing_time,
      'COMPLETED' AS status
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """]
)}}

-- Transform raw webinars data to bronze layer
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
