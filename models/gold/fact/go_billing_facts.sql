{{ config(
    materialized='table'
) }}

WITH silver_billing_events AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        source_system,
        load_date
    FROM SILVER.si_billing_events
    WHERE record_status = 'ACTIVE'
),

silver_users AS (
    SELECT 
        user_id,
        company
    FROM SILVER.si_users
    WHERE record_status = 'ACTIVE'
)

SELECT 
    CONCAT('BF_', sbe.event_id, '_', sbe.user_id) as billing_fact_id,
    sbe.event_id,
    sbe.user_id,
    COALESCE(su.company, 'INDIVIDUAL') as organization_id,
    UPPER(TRIM(sbe.event_type)) as event_type,
    ROUND(sbe.amount, 2) as amount,
    sbe.event_date,
    DATE_TRUNC('month', sbe.event_date) as billing_period_start,
    LAST_DAY(sbe.event_date) as billing_period_end,
    'Credit Card' as payment_method,
    CASE WHEN sbe.amount > 0 THEN 'Completed' ELSE 'Refunded' END as transaction_status,
    'USD' as currency_code,
    ROUND(sbe.amount * 0.08, 2) as tax_amount,
    0.00 as discount_amount,
    sbe.load_date,
    CURRENT_DATE() as update_date,
    sbe.source_system
FROM silver_billing_events sbe
LEFT JOIN silver_users su ON sbe.user_id = su.user_id
