{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

-- Create audit log table first as it will be used by other models
SELECT
  ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP()) as record_id,
  NULL as source_table,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_USER() as processed_by,
  NULL as processing_time,
  'INITIALIZED' as status
WHERE FALSE  -- Initialize with no rows
