{{ config(materialized='table') }}

WITH bronze_billing_events AS (
    SELECT * FROM {{ source('bronze', 'bz_billing_events') }}
),

users_ref AS (
    SELECT user_id FROM {{ ref('si_users') }}
),

-- Data Quality Checks
dq_checks AS (
    SELECT 
        bbe.*,
        -- Quality score calculation
        CASE 
            WHEN bbe.event_id IS NULL THEN 0
            WHEN bbe.user_id IS NULL THEN 0.2
            WHEN bbe.event_type IS NULL THEN 0.3
            WHEN bbe.amount IS NULL OR bbe.amount < 0 THEN 0.4
            WHEN bbe.event_date IS NULL THEN 0.5
            WHEN u.user_id IS NULL THEN 0.6  -- User doesn't exist
            WHEN bbe.event_type NOT IN ('Subscription Fee', 'Subscription Renewal', 'Add-on Purchase', 'Refund') THEN 0.7
            ELSE 1.0
        END AS data_quality_score,
        -- Record status
        CASE 
            WHEN bbe.event_id IS NULL OR bbe.user_id IS NULL THEN 'error'
            WHEN bbe.event_type IS NULL OR bbe.amount IS NULL OR bbe.event_date IS NULL THEN 'error'
            WHEN bbe.amount < 0 THEN 'error'
            ELSE 'active'
        END AS record_status
    FROM bronze_billing_events bbe
    LEFT JOIN users_ref u ON bbe.user_id = u.user_id
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
            ELSE TRIM(event_type)
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
    FROM dq_checks
    WHERE record_status = 'active'
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
FROM cleaned_billing_events
