{{ config(
    materialized='table'
) }}

SELECT 
    event_id as billing_fact_id,
    event_id,
    user_id,
    'INDIVIDUAL' as organization_id,
    event_type,
    amount,
    event_date,
    event_date as billing_period_start,
    event_date as billing_period_end,
    'Credit Card' as payment_method,
    'Completed' as transaction_status,
    'USD' as currency_code,
    0.00 as tax_amount,
    0.00 as discount_amount,
    load_date,
    CURRENT_DATE() as update_date,
    source_system
FROM SILVER.si_billing_events
WHERE record_status = 'ACTIVE'
