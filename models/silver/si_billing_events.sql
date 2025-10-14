{{ config(
    materialized='table',
    unique_key='event_id'
) }}

-- Silver Billing Events Table Transformation
WITH bronze_billing_events AS (
    SELECT *
    FROM {{ source('bronze', 'bz_billing_events') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Quality Score Calculation
        CASE 
            WHEN event_id IS NULL THEN 0
            WHEN user_id IS NULL THEN 0.2
            WHEN amount IS NULL OR amount < 0 THEN 0.3
            WHEN event_date IS NULL THEN 0.4
            WHEN event_type NOT IN ('Subscription Fee','Subscription Renewal','Add-on Purchase','Refund') THEN 0.6
            ELSE 1.0
        END AS data_quality_score,
        
        -- Record Status
        CASE 
            WHEN event_id IS NULL OR user_id IS NULL THEN 'error'
            WHEN amount IS NULL OR amount < 0 THEN 'error'
            WHEN event_date IS NULL THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_billing_events
),

-- Clean and Transform Data
transformed_billing_events AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(event_type)) IN ('SUBSCRIPTION FEE','SUBSCRIPTION RENEWAL','ADD-ON PURCHASE','REFUND')
            THEN UPPER(TRIM(event_type))
            ELSE 'OTHER'
        END AS event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'active'
)

SELECT * FROM transformed_billing_events
