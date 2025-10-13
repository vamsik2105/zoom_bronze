{{ config(materialized='table') }}

WITH source_data AS (
  SELECT 
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    load_timestamp,
    update_timestamp,
    source_system
  FROM {{ source('bronze', 'bz_billing_events') }}
),

-- Data Quality Validation
validated_data AS (
  SELECT 
    *,
    -- Completeness checks
    CASE WHEN event_id IS NULL THEN 1 ELSE 0 END as null_event_id,
    CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
    CASE WHEN amount IS NULL THEN 1 ELSE 0 END as null_amount,
    
    -- Range validation
    CASE WHEN amount IS NOT NULL AND amount < 0 THEN 1 ELSE 0 END as negative_amount,
    
    -- Domain validation
    CASE WHEN event_type IS NOT NULL AND event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 1 ELSE 0 END as invalid_event_type
  FROM source_data
),

-- Clean and transform data
transformed_data AS (
  SELECT 
    event_id,
    user_id,
    CASE 
      WHEN UPPER(event_type) = 'SUBSCRIPTION FEE' THEN 'Subscription Fee'
      WHEN UPPER(event_type) = 'SUBSCRIPTION RENEWAL' THEN 'Subscription Renewal'
      WHEN UPPER(event_type) = 'ADD-ON PURCHASE' THEN 'Add-on Purchase'
      WHEN UPPER(event_type) = 'REFUND' THEN 'Refund'
      ELSE event_type
    END as event_type,
    amount,
    event_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    
    -- Calculate data quality score
    CASE 
      WHEN (null_event_id + null_user_id + null_amount + negative_amount + invalid_event_type) = 0 THEN 1.0
      WHEN (null_event_id + null_user_id + null_amount + negative_amount + invalid_event_type) <= 2 THEN 0.8
      WHEN (null_event_id + null_user_id + null_amount + negative_amount + invalid_event_type) <= 3 THEN 0.6
      ELSE 0.4
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN (null_event_id + null_user_id + null_amount) > 0 THEN 'error'
      WHEN (negative_amount + invalid_event_type) > 0 THEN 'warning'
      ELSE 'active'
    END as record_status
  FROM validated_data
)

SELECT 
  event_id,
  user_id,
  event_type,
  amount,
  event_date,
  load_timestamp,
  update_timestamp,
  source_system,
  load_date,
  update_date,
  data_quality_score,
  record_status
FROM transformed_data
