{{ config(
    materialized='table',
    cluster_by=['load_date', 'user_id']
) }}

WITH billing_base AS (
    SELECT 
        b.event_id,
        b.user_id,
        b.event_type,
        b.amount,
        b.event_date,
        b.load_date,
        b.source_system,
        u.company
    FROM {{ source('silver', 'si_billing_events') }} b
    LEFT JOIN {{ source('silver', 'si_users') }} u ON b.user_id = u.user_id
    WHERE b.record_status = 'ACTIVE'
),

final_billing_facts AS (
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
)

SELECT * FROM final_billing_facts
