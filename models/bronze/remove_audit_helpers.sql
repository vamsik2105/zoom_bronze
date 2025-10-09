-- This is a placeholder file to replace the problematic audit_helpers.sql
-- It will be used to track audit information

{{config(
  materialized = 'table',
  schema = 'bronze'
)}}

SELECT
  1 as dummy_column
WHERE 1 = 0
