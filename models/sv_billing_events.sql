-- =====================================================
-- SILVER BILLING EVENTS MODEL
-- =====================================================

{{ config(
    materialized='table'
) }}

WITH bronze_billing_events AS (
    SELECT *
    FROM {{ source('bronze', 'bz_billing_events') }}
),

-- Data Quality Checks
data_quality_checks AS (
    SELECT *,
        -- Completeness checks
        CASE WHEN event_id IS NULL THEN 0 ELSE 1 END as event_id_check,
        CASE WHEN user_id IS NULL THEN 0 ELSE 1 END as user_id_check,
        CASE WHEN event_type IS NULL THEN 0 ELSE 1 END as event_type_check,
        CASE WHEN amount IS NULL THEN 0 ELSE 1 END as amount_check,
        CASE WHEN event_date IS NULL THEN 0 ELSE 1 END as event_date_check,
        CASE WHEN source_system IS NULL THEN 0 ELSE 1 END as source_system_check,
        
        -- Domain checks
        CASE WHEN event_type IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 1 ELSE 0 END as event_type_domain_check,
        
        -- Range checks
        CASE WHEN amount >= 0 THEN 1 ELSE 0 END as amount_range_check
    FROM bronze_billing_events
),

-- Calculate data quality score
quality_scored AS (
    SELECT *,
        ROUND(
            (event_id_check + user_id_check + event_type_check + amount_check + 
             event_date_check + source_system_check + event_type_domain_check + amount_range_check) / 8.0, 2
        ) as data_quality_score,
        
        -- Determine record status
        CASE 
            WHEN event_id IS NULL OR user_id IS NULL OR event_type IS NULL OR amount IS NULL OR event_date IS NULL OR source_system IS NULL THEN 'ERROR'
            WHEN event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 'ERROR'
            WHEN amount < 0 THEN 'ERROR'
            ELSE 'ACTIVE'
        END as record_status
    FROM data_quality_checks
),

-- Final transformation
final_billing_events AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN event_type IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN event_type
            ELSE 'Other'
        END as event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) as load_date,
        DATE(update_timestamp) as update_date,
        data_quality_score,
        record_status
    FROM quality_scored
    WHERE record_status = 'ACTIVE'
)

SELECT * FROM final_billing_events
