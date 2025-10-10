{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_support_tickets', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', 0, 'STARTED')",
    post_hook="INSERT INTO {{ this.schema }}.bz_audit_log (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('bz_support_tickets', CURRENT_TIMESTAMP(), 'dbt_bronze_layer', DATEDIFF('second', (SELECT MAX(load_timestamp) FROM {{ this.schema }}.bz_audit_log WHERE source_table = 'bz_support_tickets' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED')"
) }}

-- Bronze layer transformation for support_tickets table
SELECT 
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'support_tickets') }}
