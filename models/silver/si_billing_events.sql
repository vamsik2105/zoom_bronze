{{ config(
    materialized='table'
) }}

-- Billing Events Silver Layer Transformation
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
    FROM BRONZE.bz_billing_events
    WHERE load_timestamp IS NOT NULL
),

validated_billing_events AS (
    SELECT *,
        CASE 
            WHEN event_id IS NULL OR TRIM(event_id) = '' THEN 'Missing event_id'
            WHEN user_id IS NULL OR TRIM(user_id) = '' THEN 'Missing user_id'
            WHEN event_type IS NULL OR TRIM(event_type) = '' THEN 'Missing event_type'
            WHEN UPPER(TRIM(event_type)) NOT IN ('SUBSCRIPTION FEE', 'SUBSCRIPTION RENEWAL', 'ADD-ON PURCHASE', 'REFUND') THEN 'Invalid event_type'
            WHEN amount IS NULL OR amount < 0 THEN 'Invalid amount'
            WHEN event_date IS NULL THEN 'Missing event_date'
            ELSE NULL
        END AS validation_error
    FROM bronze_billing_events
),

transformed_billing_events AS (
    SELECT 
        TRIM(event_id) as event_id,
        TRIM(user_id) as user_id,
        CASE 
            WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION FEE' THEN 'Subscription Fee'
            WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION RENEWAL' THEN 'Subscription Renewal'
            WHEN UPPER(TRIM(event_type)) = 'ADD-ON PURCHASE' THEN 'Add-on Purchase'
            WHEN UPPER(TRIM(event_type)) = 'REFUND' THEN 'Refund'
            ELSE 'Other'
        END as event_type,
        COALESCE(amount, 0.00) as amount,
        event_date,
        load_timestamp,
        update_timestamp,
        COALESCE(source_system, 'UNKNOWN') as source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        CASE 
            WHEN validation_error IS NULL THEN 1.0
            ELSE 0.0
        END as data_quality_score,
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status
    FROM validated_billing_events
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
FROM transformed_billing_events
