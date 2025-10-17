{{ config(
    materialized='table',
    cluster_by=['event_date', 'user_id'],
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed) VALUES (CONCAT('EXEC_', CURRENT_TIMESTAMP()::STRING), 'go_billing_facts', 'FACT_LOAD', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_USER()) WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}) WHERE pipeline_name = 'go_billing_facts' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
) }}

WITH billing_base AS (
    SELECT 
        b.event_id,
        b.user_id,
        b.event_type,
        b.amount,
        b.event_date,
        b.load_date,
        b.source_system
    FROM {{ ref('si_billing_events') }} b
    WHERE b.record_status = 'ACTIVE'
),

user_organizations AS (
    SELECT 
        u.user_id,
        COALESCE(u.company, 'INDIVIDUAL') as organization_id
    FROM {{ ref('si_users') }} u
    WHERE u.record_status = 'ACTIVE'
)

SELECT 
    CONCAT('BF_', bb.event_id, '_', bb.user_id) as billing_fact_id,
    bb.event_id,
    bb.user_id,
    COALESCE(uo.organization_id, 'INDIVIDUAL') as organization_id,
    UPPER(TRIM(bb.event_type)) as event_type,
    ROUND(bb.amount, 2) as amount,
    bb.event_date,
    DATE_TRUNC('month', bb.event_date) as billing_period_start,
    LAST_DAY(bb.event_date) as billing_period_end,
    'Credit Card' as payment_method,
    CASE 
        WHEN bb.amount > 0 THEN 'Completed' 
        ELSE 'Refunded' 
    END as transaction_status,
    'USD' as currency_code,
    ROUND(bb.amount * 0.08, 2) as tax_amount,
    0.00 as discount_amount,
    bb.load_date,
    CURRENT_DATE() as update_date,
    bb.source_system
FROM billing_base bb
LEFT JOIN user_organizations uo ON bb.user_id = uo.user_id
