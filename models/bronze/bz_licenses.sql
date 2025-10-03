{{config(
  materialized = 'incremental',
  pre_hook=[
    "{% if target.table != 'bz_audit_log' %}
      INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, status)
      VALUES ('licenses', CURRENT_TIMESTAMP(), CURRENT_USER(), 'STARTED')
    {% endif %}"
  ],
  post_hook=[
    "{% if target.table != 'bz_audit_log' %}
      INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
      VALUES ('licenses', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('MILLISECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'licenses' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')
    {% endif %}"
  ]
)}}

SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_TIMESTAMP() AS update_timestamp,
  'ZOOM_PLATFORM' AS source_system
FROM {{ source('raw', 'licenses') }}
