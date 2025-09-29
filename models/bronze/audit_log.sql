{{config(
  materialized = 'table'
)}}

-- Create audit log table for tracking model execution
CREATE TABLE IF NOT EXISTS {{ this }} (
  audit_id INTEGER AUTOINCREMENT,
  model_name VARCHAR(255),
  status VARCHAR(50),
  start_time TIMESTAMP_NTZ,
  end_time TIMESTAMP_NTZ,
  rows_affected INTEGER,
  error_message VARCHAR(1000)
)
