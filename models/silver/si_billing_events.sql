{{ config(
    materialized='table'
) }}

WITH bronze_billing_events AS (
    SELECT *
    FROM BRONZE.bz_billing_events
),

-- Data Quality Validations
validated_billing_events AS (
    SELECT *,
        CASE 
            WHEN event_id IS NULL THEN 'Missing event_id'
            WHEN user_id IS NULL THEN 'Missing user_id'
            WHEN event_type IS NULL THEN 'Missing event_type'
            WHEN event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 'Invalid event_type'
            WHEN amount IS NULL OR amount < 0 THEN 'Invalid amount'
            WHEN event_date IS NULL THEN 'Missing event_date'
            ELSE NULL
        END AS validation_error
    FROM bronze_billing_events
),

-- Clean and Transform Data
transformed_billing_events AS (
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
        CASE 
            WHEN validation_error IS NULL THEN 'active'
            ELSE 'error'
        END as record_status,
        validation_error
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
    {{ calculate_data_quality_score('transformed_billing_events') }} as data_quality_score,
    record_status
FROM transformed_billing_events
WHERE validation_error IS NULL

UNION ALL

-- Error Records for Audit
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
    0.0 as data_quality_score,
    'error' as record_status
FROM transformed_billing_events
WHERE validation_error IS NOT NULL
