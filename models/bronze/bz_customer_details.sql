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
      CAST('RUNNING' AS VARCHAR(50)),
      CAST('SYSTEM' AS VARCHAR(100)),
      CAST('CUSTOMER_DETAILS' AS VARCHAR(255)),
      CAST('CUSTOMER_DETAILS_BRZ' AS VARCHAR(255)),
      CAST('bz_customer_details' AS VARCHAR(255)),
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
      CAST('COMPLETED' AS VARCHAR(50)),
      CAST('SYSTEM' AS VARCHAR(100)),
      CAST('CUSTOMER_DETAILS' AS VARCHAR(255)),
      CAST('CUSTOMER_DETAILS_BRZ' AS VARCHAR(255)),
      CAST('bz_customer_details' AS VARCHAR(255)),
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
    CAST('PROCESSED' AS VARCHAR(50)) AS process_status
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
