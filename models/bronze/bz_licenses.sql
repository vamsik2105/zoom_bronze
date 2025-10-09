{{config(
  materialized = 'incremental',
  unique_key = 'license_id',
  pre_hook=[
    "{% if not is_incremental() and this.name != 'bz_audit_log' %}
      INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 'licenses', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, 'PROCESSING'
    {% endif %}"
  ],
  post_hook=[
    "{% if not is_incremental() and this.name != 'bz_audit_log' %}
      INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status)
      SELECT 'licenses', CURRENT_TIMESTAMP(), CURRENT_USER(), DATEDIFF('SECOND', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'licenses' AND status = 'PROCESSING'), CURRENT_TIMESTAMP()), 'SUCCESS'
    {% endif %}"
  ]
)}}

SELECT
  license_id,
  license_type,
  assigned_to_user_id,
  start_date,
  end_date,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_TIMESTAMP() as update_timestamp,
  'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'licenses') }}
