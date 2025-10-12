{{
  config(
    materialized='table'
  )
}}

-- Transform bronze billing events to silver billing events with data quality checks
WITH bronze_billing_events AS (
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

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN event_id IS NULL OR event_id = '' THEN 'INVALID_EVENT_ID'
            WHEN user_id IS NULL OR user_id = '' THEN 'MISSING_USER_ID'
            WHEN event_type IS NULL OR event_type = '' THEN 'MISSING_EVENT_TYPE'
            WHEN event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 'INVALID_EVENT_TYPE'
            WHEN amount IS NULL OR amount < 0 THEN 'INVALID_AMOUNT'
            WHEN event_date IS NULL THEN 'MISSING_EVENT_DATE'
            ELSE 'VALID'
        END as validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN event_id IS NULL OR event_id = '' THEN 0.0
            WHEN user_id IS NULL OR user_id = '' THEN 0.3
            WHEN event_type IS NULL OR event_type = '' THEN 0.5
            WHEN amount IS NULL OR amount < 0 THEN 0.7
            ELSE 1.0
        END as data_quality_score
    FROM bronze_billing_events
),

cleaned_billing_events AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(event_type) LIKE '%SUBSCRIPTION%' AND UPPER(event_type) LIKE '%FEE%' THEN 'Subscription Fee'
            WHEN UPPER(event_type) LIKE '%SUBSCRIPTION%' AND UPPER(event_type) LIKE '%RENEWAL%' THEN 'Subscription Renewal'
            WHEN UPPER(event_type) LIKE '%ADD%' OR UPPER(event_type) LIKE '%PURCHASE%' THEN 'Add-on Purchase'
            WHEN UPPER(event_type) LIKE '%REFUND%' THEN 'Refund'
            ELSE event_type
        END as event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END as record_status
    FROM data_quality_checks
    WHERE validation_status = 'VALID'
)

SELECT * FROM cleaned_billing_events
