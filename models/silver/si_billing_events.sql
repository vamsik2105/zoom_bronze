{{ config(materialized='table') }}

-- Silver Billing Events Table
WITH bronze_billing_events AS (
    SELECT *
    FROM {{ source('bronze', 'bz_billing_events') }}
),

valid_users AS (
    SELECT DISTINCT user_id FROM {{ ref('si_users') }}
),

data_quality_checks AS (
    SELECT 
        bbe.*,
        
        -- Completeness checks
        CASE WHEN event_id IS NULL THEN 1 ELSE 0 END as missing_event_id,
        CASE WHEN user_id IS NULL THEN 1 ELSE 0 END as missing_user_id,
        CASE WHEN amount IS NULL THEN 1 ELSE 0 END as missing_amount,
        CASE WHEN event_date IS NULL THEN 1 ELSE 0 END as missing_event_date,
        
        -- Domain validation
        CASE WHEN event_type IS NOT NULL AND event_type NOT IN 
             ('Subscription Fee','Subscription Renewal','Add-on Purchase','Refund') 
             THEN 1 ELSE 0 END as invalid_event_type,
        
        -- Range validation
        CASE WHEN amount IS NOT NULL AND amount < 0 THEN 1 ELSE 0 END as invalid_amount,
        
        -- Referential integrity
        CASE WHEN vu.user_id IS NULL THEN 1 ELSE 0 END as invalid_user_ref,
        
        -- Calculate data quality score
        CASE 
            WHEN event_id IS NULL OR user_id IS NULL OR amount IS NULL OR event_date IS NULL THEN 0.0
            WHEN vu.user_id IS NULL THEN 0.2
            WHEN event_type NOT IN ('Subscription Fee','Subscription Renewal','Add-on Purchase','Refund') THEN 0.4
            WHEN amount < 0 THEN 0.6
            ELSE 1.0
        END as data_quality_score
    FROM bronze_billing_events bbe
    LEFT JOIN valid_users vu ON bbe.user_id = vu.user_id
)

SELECT 
    event_id,
    user_id,
    CASE 
        WHEN event_type IN ('Subscription Fee','Subscription Renewal','Add-on Purchase','Refund') 
        THEN event_type
        ELSE 'Subscription Fee'  -- Default for invalid values
    END as event_type,
    CASE WHEN amount >= 0 THEN amount ELSE 0.00 END as amount,
    event_date,
    load_timestamp,
    update_timestamp,
    source_system,
    DATE(load_timestamp) as load_date,
    DATE(update_timestamp) as update_date,
    data_quality_score,
    CASE 
        WHEN missing_event_id = 1 OR missing_user_id = 1 OR missing_amount = 1 
             OR missing_event_date = 1 OR invalid_user_ref = 1
        THEN 'error'
        ELSE 'active'
    END as record_status
FROM data_quality_checks
WHERE CASE 
        WHEN missing_event_id = 1 OR missing_user_id = 1 OR missing_amount = 1 
             OR missing_event_date = 1 OR invalid_user_ref = 1
        THEN 'error'
        ELSE 'active'
    END = 'active'
