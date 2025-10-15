{{ config(
    materialized='table'
) }}

-- Billing Facts transformation from Silver to Gold
WITH silver_billing_events AS (
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
    FROM {{ source('silver_schema', 'si_billing_events') }}
    WHERE record_status = 'ACTIVE'
      AND COALESCE(data_quality_score, 0) >= 0.7
      AND amount IS NOT NULL
      AND event_date IS NOT NULL
),

billing_facts_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['event_id']) }} AS billing_fact_id,
        b.event_id,
        b.user_id,
        'ORG_' || b.user_id AS organization_id,
        b.event_type,
        b.amount,
        b.event_date,
        DATE_TRUNC('month', b.event_date) AS billing_period_start,
        LAST_DAY(b.event_date) AS billing_period_end,
        'Credit Card' AS payment_method,
        'Completed' AS transaction_status,
        'USD' AS currency_code,
        ROUND(b.amount * 0.08, 2) AS tax_amount,
        0.00 AS discount_amount,
        b.load_date,
        b.update_date,
        b.source_system
    FROM silver_billing_events b
)

SELECT * FROM billing_facts_final
