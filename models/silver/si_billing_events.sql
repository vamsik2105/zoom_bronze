-- Silver Billing Events Table - Cleaned and validated billing event data

{{ config(
    materialized='table',
    unique_key='event_id'
) }}

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

validated_billing_events AS (
    SELECT 
        *,
        CASE 
            WHEN event_id IS NULL THEN 'NULL_EVENT_ID'
            WHEN user_id IS NULL THEN 'NULL_USER_ID'
            WHEN event_type IS NULL THEN 'NULL_EVENT_TYPE'
            WHEN event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 'INVALID_EVENT_TYPE'
            WHEN amount IS NULL OR amount < 0 THEN 'INVALID_AMOUNT'
            WHEN event_date IS NULL THEN 'NULL_EVENT_DATE'
            WHEN source_system IS NULL THEN 'NULL_SOURCE_SYSTEM'
            ELSE 'VALID'
        END AS validation_status
    FROM bronze_billing_events
),

transformed_billing_events AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION FEE' THEN 'Subscription Fee'
            WHEN UPPER(TRIM(event_type)) = 'SUBSCRIPTION RENEWAL' THEN 'Subscription Renewal'
            WHEN UPPER(TRIM(event_type)) = 'ADD-ON PURCHASE' THEN 'Add-on Purchase'
            WHEN UPPER(TRIM(event_type)) = 'REFUND' THEN 'Refund'
            ELSE event_type
        END AS event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        {{ calculate_data_quality_score('si_billing_events', 'event_id') }} AS data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status,
        validation_status
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
WHERE validation_status = 'VALID'

UNION ALL

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
    0.0 AS data_quality_score,
    'error' AS record_status
FROM transformed_billing_events
WHERE validation_status != 'VALID'
