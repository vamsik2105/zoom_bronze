-- Create the audit log table first as it will be referenced by other models
{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

-- Initial creation of the audit log table
SELECT
  NULL as record_id,  -- This will be auto-incremented
  'INITIAL' as source_table,
  CURRENT_TIMESTAMP() as load_timestamp,
  'DBT' as processed_by,
  0 as processing_time,
  'INITIALIZED' as status
WHERE 1=0  -- Empty initial table
