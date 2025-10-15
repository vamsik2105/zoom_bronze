{{ config(
    materialized='table'
) }}

WITH billing_base AS (
    SELECT 
        be.event_id,
        be.user_id,
        be.event_type,
        be.amount,
        be.event_date,
        be.load_date,
        be.source_system,
        u.company
    FROM {{ source('silver', 'si_billing_events') }} be
    LEFT JOIN {{ source('silver', 'si_users') }} u ON be.user_id = u.user_id
    WHERE be.record_status = 'ACTIVE'
)

SELECT 
    CONCAT('BF_', bb.event_id, '_', bb.user_id) as billing_fact_id,
    bb.event_id,
    bb.user_id,
    COALESCE(bb.company, 'INDIVIDUAL') as organization_id,
    UPPER(TRIM(bb.event_type)) as event_type,
    ROUND(bb.amount, 2) as amount,
    bb.event_date,
    DATE_TRUNC('month', bb.event_date) as billing_period_start,
    LAST_DAY(bb.event_date) as billing_period_end,
    'Credit Card' as payment_method,
    CASE WHEN bb.amount > 0 THEN 'Completed' ELSE 'Refunded' END as transaction_status,
    'USD' as currency_code,
    ROUND(bb.amount * 0.08, 2) as tax_amount,
    0.00 as discount_amount,
    bb.load_date,
    CURRENT_DATE() as update_date,
    bb.source_system
FROM billing_base bb
