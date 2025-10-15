{{ config(
    materialized='table'
) }}

-- Gold Billing Facts Table
-- Creates fact table for billing analytics

WITH silver_billing AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        source_system,
        load_date,
        update_date
    FROM SILVER.si_billing_events
    WHERE record_status = 'ACTIVE'
      AND data_quality_score >= 0.7
),

billing_facts AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['event_id']) }} as billing_fact_id,
        event_id,
        user_id,
        {{ dbt_utils.generate_surrogate_key(['user_id']) }} as organization_id,
        event_type,
        amount,
        event_date,
        DATE_TRUNC('MONTH', event_date) as billing_period_start,
        LAST_DAY(event_date) as billing_period_end,
        'Credit Card' as payment_method,
        'Completed' as transaction_status,
        'USD' as currency_code,
        ROUND(amount * 0.08, 2) as tax_amount,
        0.00 as discount_amount,
        load_date,
        update_date,
        source_system
    FROM silver_billing
)

SELECT * FROM billing_facts
