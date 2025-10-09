{{config(
  materialized = 'incremental',
  unique_key = 'log_id'
)}}

-- Create audit log table with appropriate column sizes
WITH source AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['current_timestamp', 'random()']) }} AS log_id,
    current_timestamp() AS created_at,
    NULL AS updated_at,
    CAST('PENDING' AS VARCHAR(50)) AS process_status,
    CAST('SYSTEM' AS VARCHAR(100)) AS created_by,
    CAST(NULL AS VARCHAR(100)) AS updated_by,
    CAST(NULL AS VARCHAR(255)) AS source_table,
    CAST(NULL AS VARCHAR(255)) AS target_table,
    CAST(NULL AS VARCHAR(255)) AS process_name,
    NULL AS start_time,
    NULL AS end_time,
    NULL AS row_count,
    CAST(NULL AS VARCHAR(4000)) AS error_message
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
