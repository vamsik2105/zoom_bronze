-- Bronze layer transformation for billing events data
-- Maps raw billing event data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_billing_events') }}""",
    post_hook = """{{ log_table_process_end('bz_billing_events', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    Event_ID as event_id,
    User_ID as user_id,
    Event_Type as event_type,
    Amount as amount,
    Event_Date as event_date,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'billing_events') }}
