{{config(
  materialized = 'table',
  schema = 'bronze',
  pre_hook=[
    "{% if target.table_name != 'bz_audit_log' %}
       INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
       SELECT 'users', CURRENT_TIMESTAMP, CURRENT_USER(), 0, 'STARTED'
     {% endif %}"
  ],
  post_hook=[
    "{% if target.table_name != 'bz_audit_log' %}
       INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
       SELECT 'users', CURRENT_TIMESTAMP, CURRENT_USER(), DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'users' AND status = 'STARTED'), CURRENT_TIMESTAMP), 'COMPLETED'
     {% endif %}"
  ]
)}}

-- Transform raw users data to bronze layer
SELECT
  user_id,
  user_name,
  email,
  company,
  plan_type,
  CURRENT_TIMESTAMP AS load_timestamp,
  CURRENT_TIMESTAMP AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'users') }}
