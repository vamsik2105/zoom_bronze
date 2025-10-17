{{ config(
    materialized='table',
    cluster_by=['event_date', 'user_id']
) }}

SELECT 
    CONCAT('BF_', event_id, '_', user_id) as billing_fact_id,
    event_id,
    user_id,
    'INDIVIDUAL' as organization_id,
    UPPER(TRIM(event_type)) as event_type,
    ROUND(amount, 2) as amount,
    event_date,
    DATE_TRUNC('month', event_date) as billing_period_start,
    LAST_DAY(event_date) as billing_period_end,
    'Credit Card' as payment_method,
    CASE 
        WHEN amount > 0 THEN 'Completed' 
        ELSE 'Refunded' 
    END as transaction_status,
    'USD' as currency_code,
    ROUND(amount * 0.08, 2) as tax_amount,
    0.00 as discount_amount,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM ZOOM.SILVER.si_billing_events
WHERE record_status = 'ACTIVE'
