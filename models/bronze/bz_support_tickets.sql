-- Bronze layer transformation for support tickets data
-- Maps raw support ticket data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_support_tickets') }}""",
    post_hook = """{{ log_table_process_end('bz_support_tickets', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    Ticket_ID as ticket_id,
    User_ID as user_id,
    Ticket_Type as ticket_type,
    Resolution_Status as resolution_status,
    Open_Date as open_date,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'support_tickets') }}
