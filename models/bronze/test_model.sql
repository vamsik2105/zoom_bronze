-- Simple test model to verify DBT job execution
SELECT
  1 as id,
  'test' as name,
  CURRENT_TIMESTAMP() as created_at
