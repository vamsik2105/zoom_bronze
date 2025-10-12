-- Silver layer billing events table with data quality checks and transformations
-- Transforms bronze billing events data with validation and cleansing

{{ config(
    materialized='table'
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

-- Data quality validation
validated_billing_events AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN event_id IS NULL THEN 1 ELSE 0 END as null_event_id,
        CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as null_user_id,
        CASE WHEN amount IS NULL THEN 1 ELSE 0 END as null_amount,
        
        -- Domain validation
        CASE WHEN event_type IS NOT NULL AND event_type NOT IN ('Subscription Fee','Subscription Renewal','Add-on Purchase','Refund') 
             THEN 1 ELSE 0 END as invalid_event_type,
        
        -- Range validation
        CASE WHEN amount IS NOT NULL AND amount < 0 
             THEN 1 ELSE 0 END as invalid_amount
    FROM bronze_billing_events
),

-- Clean and transform data
cleaned_billing_events AS (
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
        
        -- Data quality flags
        null_event_id + null_user_id + null_amount + invalid_event_type + invalid_amount as error_count,
        
        -- Record status
        CASE 
            WHEN null_event_id = 1 OR null_user_id = 1 OR null_amount = 1 OR invalid_amount = 1 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM validated_billing_events
),

-- Calculate data quality score
final_billing_events AS (
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
        
        -- Data quality score calculation
        CASE 
            WHEN error_count = 0 THEN 1.0
            WHEN error_count = 1 THEN 0.8
            WHEN error_count = 2 THEN 0.6
            WHEN error_count = 3 THEN 0.4
            WHEN error_count = 4 THEN 0.2
            ELSE 0.0
        END as data_quality_score,
        
        record_status
    FROM cleaned_billing_events
    WHERE record_status = 'active'  -- Only include valid records
)

SELECT * FROM final_billing_events
