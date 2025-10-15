{{ config(
    materialized='table'
) }}

SELECT 
    'BILLING_001' AS billing_fact_id,
    'E001' AS event_id,
    'U001' AS user_id,
    'ORG_001' AS organization_id,
    'Subscription' AS event_type,
    99.99 AS amount,
    '2024-01-01'::date AS event_date,
    '2024-01-01'::date AS billing_period_start,
    '2024-01-31'::date AS billing_period_end,
    'Credit Card' AS payment_method,
    'Completed' AS transaction_status,
    'USD' AS currency_code,
    8.00 AS tax_amount,
    0.00 AS discount_amount,
    CURRENT_DATE() AS load_date,
    CURRENT_DATE() AS update_date,
    'SILVER' AS source_system
