{{ config(
    materialized='table'
) }}

WITH source_billing AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_date,
        update_date,
        source_system
    FROM SILVER.si_billing_events
    WHERE event_id IS NOT NULL
),

final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['event_id']) }} as billing_fact_id,
        event_id,
        user_id,
        'ORG_001' as organization_id,
        event_type,
        amount,
        event_date,
        DATE_TRUNC('month', event_date) as billing_period_start,
        LAST_DAY(event_date) as billing_period_end,
        'Credit Card' as payment_method,
        'Completed' as transaction_status,
        'USD' as currency_code,
        ROUND(amount * 0.08, 2) as tax_amount,
        0.00 as discount_amount,
        load_date,
        update_date,
        source_system
    FROM source_billing
)

SELECT * FROM final
