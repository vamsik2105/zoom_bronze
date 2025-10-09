{{config(
  materialized = 'incremental',
  unique_key = 'log_id'
)}}

WITH source AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['current_timestamp', 'random()']) }} AS log_id,
    current_timestamp() AS created_at,
    NULL AS updated_at,
    'PENDING' AS process_status,
    'SYSTEM' AS created_by,
    NULL AS updated_by,
    NULL AS source_table,
    NULL AS target_table,
    NULL AS process_name,
    NULL AS start_time,
    NULL AS end_time,
    NULL AS row_count,
    NULL AS error_message
  WHERE FALSE  -- This ensures the audit log model itself doesn't create entries when built
)

SELECT
  log_id,
  created_at,
  updated_at,
  process_status,
  created_by,
  updated_by,
  source_table,
  target_table,
  process_name,
  start_time,
  end_time,
  row_count,
  error_message
FROM source
