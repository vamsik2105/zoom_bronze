{{ config(materialized='table') }}

WITH bronze_billing_events AS (
    SELECT *
    FROM {{ source('bronze', 'bz_billing_events') }}
),

-- Data Quality Checks
quality_checks AS (
    SELECT 
        *,
        -- Completeness checks
        CASE WHEN event_id IS NULL THEN 0 ELSE 1 END as event_id_complete,
        CASE WHEN user_id IS NULL THEN 0 ELSE 1 END as user_id_complete,
        CASE WHEN amount IS NULL THEN 0 ELSE 1 END as amount_complete,
        CASE WHEN event_date IS NULL THEN 0 ELSE 1 END as event_date_complete,
        
        -- Domain checks
        CASE WHEN event_type IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 1 ELSE 0 END as event_type_valid,
        CASE WHEN amount >= 0 THEN 1 ELSE 0 END as amount_valid
    FROM bronze_billing_events
),

-- Calculate data quality score
scored_data AS (
    SELECT 
        *,
        ROUND(
            (event_id_complete + user_id_complete + amount_complete + event_date_complete + event_type_valid + amount_valid) / 6.0, 2
        ) as data_quality_score,
        CASE 
            WHEN event_id IS NULL OR user_id IS NULL OR amount IS NULL OR event_date IS NULL THEN 'error'
            WHEN amount < 0 THEN 'error'
            ELSE 'active'
        END as record_status
    FROM quality_checks
),

-- Final transformation
final_data AS (
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
    FROM scored_data
    WHERE record_status = 'active'
)

SELECT * FROM final_data
