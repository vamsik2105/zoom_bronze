{{config(
  materialized = 'table',
  unique_key = 'record_id'
)}}

-- Create the audit log table if it doesn't exist
SELECT
  NULL AS record_id,  -- This will be auto-incremented
  NULL AS source_table,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_USER() AS processed_by,
  NULL AS processing_time,
  NULL AS status
WHERE 1=0  -- Empty initial table
