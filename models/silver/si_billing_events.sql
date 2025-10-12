{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('si_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'si_billing_events', CURRENT_TIMESTAMP(), 'dbt_transformation', 0, 'STARTED'",
    post_hook="UPDATE {{ ref('si_audit_log') }} SET status = 'COMPLETED', processing_time = 10 WHERE source_table = 'si_billing_events' AND status = 'STARTED'"
) }}

-- Transform bronze billing events data to silver layer with data quality checks
WITH bronze_billing_events AS (
    SELECT *
    FROM {{ source('bronze', 'bz_billing_events') }}
),

-- Data quality validation
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
            ELSE 'VALID'
        END AS validation_status,
        
        -- Calculate data quality score
        CASE 
            WHEN event_id IS NOT NULL 
                AND user_id IS NOT NULL 
                AND event_type IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund')
                AND amount >= 0
                AND event_date IS NOT NULL
            THEN 1.0
            WHEN event_id IS NOT NULL AND user_id IS NOT NULL
            THEN 0.75
            WHEN event_id IS NOT NULL
            THEN 0.5
            ELSE 0.0
        END AS data_quality_score
    FROM bronze_billing_events
),

-- Clean and transform valid records
clean_billing_events AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(event_type) = 'SUBSCRIPTION FEE' THEN 'Subscription Fee'
            WHEN UPPER(event_type) = 'SUBSCRIPTION RENEWAL' THEN 'Subscription Renewal'
            WHEN UPPER(event_type) = 'ADD-ON PURCHASE' THEN 'Add-on Purchase'
            WHEN UPPER(event_type) = 'REFUND' THEN 'Refund'
            ELSE event_type
        END AS event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        CASE 
            WHEN validation_status = 'VALID' THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM validated_billing_events
    WHERE validation_status = 'VALID'
)

SELECT * FROM clean_billing_events
