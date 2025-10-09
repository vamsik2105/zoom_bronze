{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

-- Create audit log table to track processing of bronze models
SELECT
  ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS record_id,
  CAST(NULL AS VARCHAR(255)) AS source_table,
  CURRENT_TIMESTAMP() AS load_timestamp,
  CURRENT_USER() AS processed_by,
  CAST(NULL AS NUMBER) AS processing_time,
  CAST(NULL AS STRING) AS status
WHERE 1 = 0  -- Create empty table structure
