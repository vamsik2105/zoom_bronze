{{config(
  materialized = 'incremental',
  unique_key = 'record_id'
)}}

-- Create audit log table to track processing of all models
SELECT
  -- Using Snowflake's AUTOINCREMENT feature for record_id
  NULL as record_id,
  'INITIAL_SETUP' as source_table,
  CURRENT_TIMESTAMP() as load_timestamp,
  CURRENT_USER() as processed_by,
  0 as processing_time,
  'SUCCESS' as status
WHERE FALSE  -- Don't insert any rows on initial creation
