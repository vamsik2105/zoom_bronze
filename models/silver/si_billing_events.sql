{{
  config(
    materialized='table'
  )
}}

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
    CASE 
      WHEN event_id IS NULL THEN 'MISSING_EVENT_ID'
      WHEN user_id IS NULL THEN 'MISSING_USER_ID'
      WHEN event_type IS NULL THEN 'MISSING_EVENT_TYPE'
      WHEN amount IS NULL THEN 'MISSING_AMOUNT'
      WHEN event_date IS NULL THEN 'MISSING_EVENT_DATE'
      ELSE 'VALID'
    END as completeness_status,
    
    -- Domain and range validation
    CASE 
      WHEN event_type IS NOT NULL AND event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 'INVALID_EVENT_TYPE'
      WHEN amount IS NOT NULL AND amount < 0 THEN 'INVALID_AMOUNT'
      ELSE 'VALID_DOMAIN'
    END as domain_status
  FROM source_data
),

-- Clean and transform data
cleaned_data AS (
  SELECT 
    event_id,
    user_id,
    CASE 
      WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION FEE' THEN 'Subscription Fee'
      WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION RENEWAL' THEN 'Subscription Renewal'
      WHEN UPPER(TRIM(event_type)) = 'ADD-ON PURCHASE' THEN 'Add-on Purchase'
      WHEN UPPER(TRIM(event_type)) = 'REFUND' THEN 'Refund'
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
      WHEN completeness_status != 'VALID' OR domain_status != 'VALID_DOMAIN' THEN 0.0
      WHEN event_id IS NOT NULL AND user_id IS NOT NULL AND event_type IS NOT NULL AND amount IS NOT NULL THEN 1.0
      ELSE 0.7
    END as data_quality_score,
    
    -- Set record status
    CASE 
      WHEN completeness_status = 'VALID' AND domain_status = 'VALID_DOMAIN' THEN 'active'
      ELSE 'error'
    END as record_status,
    
    completeness_status,
    domain_status
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
FROM cleaned_data
WHERE record_status = 'active'
