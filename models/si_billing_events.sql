-- Silver layer billing events table with data quality checks and transformations
-- Transforms bronze billing events data with validation and cleansing

{{ config(
    materialized='table'
) }}

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
    1.0 as data_quality_score,
    'active' as record_status
FROM {{ source('bronze', 'bz_billing_events') }}
WHERE event_id IS NOT NULL
  AND user_id IS NOT NULL
  AND amount IS NOT NULL
