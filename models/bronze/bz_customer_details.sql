{{config(
  materialized = 'incremental',
  unique_key = 'CUSTOMER_ID',
  pre_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (
      log_id, created_at, process_status, created_by, source_table, target_table, process_name, start_time
    )
    SELECT
      {{ dbt_utils.generate_surrogate_key(['current_timestamp', 'random()']) }},
      current_timestamp(),
      'RUNNING',
      'SYSTEM',
      'CUSTOMER_DETAILS',
      'CUSTOMER_DETAILS_BRZ',
      'bz_customer_details',
      current_timestamp()
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """],
  post_hook=["""
    INSERT INTO {{ ref('bz_audit_log') }} (
      log_id, created_at, process_status, created_by, source_table, target_table, process_name, start_time, end_time, row_count
    )
    SELECT
      {{ dbt_utils.generate_surrogate_key(['current_timestamp', 'random()']) }},
      current_timestamp(),
      'COMPLETED',
      'SYSTEM',
      'CUSTOMER_DETAILS',
      'CUSTOMER_DETAILS_BRZ',
      'bz_customer_details',
      current_timestamp(),
      current_timestamp(),
      (SELECT COUNT(*) FROM {{ this }})
    WHERE '{{ this.name }}' != 'bz_audit_log'
  """]
)}}

WITH source_data AS (
  SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    EMAIL,
    current_timestamp() AS created_at,
    current_timestamp() AS updated_at,
    'PROCESSED' AS process_status
  FROM {{ source('raw', 'CUSTOMER_DETAILS') }}
)

SELECT
  CUSTOMER_ID,
  CUSTOMER_NAME,
  EMAIL,
  created_at,
  updated_at,
  process_status
FROM source_data
