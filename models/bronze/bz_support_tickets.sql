{{ config(
    materialized='table'
) }}

-- Transform raw support_tickets data to bronze layer with 1-to-1 mapping
SELECT
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    CURRENT_TIMESTAMP() as bronze_created_at,
    'dbt' as bronze_created_by
FROM {{ source('raw', 'support_tickets') }}
WHERE ticket_id IS NOT NULL
