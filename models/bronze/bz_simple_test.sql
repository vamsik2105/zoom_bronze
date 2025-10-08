{{config(
  materialized = 'table'
)}}

-- Simple test model
SELECT
  1 as test_id,
  'test' as test_value
