{{config(
  materialized = 'table'
)}}

-- Create audit log table to track processing of all models
SELECT
  1 as record_id,
  'INITIAL_SETUP' as source_table,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_USER() as processed_by,
  0 as processing_time,
  'SUCCESS' as status
