{{ config(
    materialized='table'
) }}

SELECT 
    'BF_001' as billing_fact_id,
    'EVENT_001' as event_id,
    'USER_001' as user_id,
    'COMPANY_001' as organization_id,
    'SUBSCRIPTION' as event_type,
    29.99 as amount,
    CURRENT_DATE() as event_date,
    DATE_TRUNC('month', CURRENT_DATE()) as billing_period_start,
    LAST_DAY(CURRENT_DATE()) as billing_period_end,
    'Credit Card' as payment_method,
    'Completed' as transaction_status,
    'USD' as currency_code,
    2.40 as tax_amount,
    0.00 as discount_amount,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'ZOOM_ANALYTICS' as source_system
