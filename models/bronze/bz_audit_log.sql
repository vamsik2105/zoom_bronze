{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

-- Create audit log table to track processing of bronze models
SELECT
  ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP) AS record_id,
  CAST(NULL AS VARCHAR(255)) AS source_table,
  CURRENT_TIMESTAMP AS load_timestamp,
  CURRENT_USER() AS processed_by,
  0 AS processing_time,
  'INITIALIZED' AS status
WHERE FALSE  -- Initialize with no records
