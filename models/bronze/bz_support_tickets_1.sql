{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_support_tickets', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_support_tickets transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_support_tickets', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_support_tickets transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for support tickets
WITH source_support_tickets AS (
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
),

-- Data quality checks and transformations
cleaned_support_tickets AS (
    SELECT 
        COALESCE(ticket_id, 'UNKNOWN') as ticket_id,
        COALESCE(user_id, 'UNKNOWN') as user_id,
        COALESCE(ticket_type, 'UNKNOWN') as ticket_type,
        COALESCE(resolution_status, 'UNKNOWN') as resolution_status,
        open_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_support_tickets
    WHERE ticket_id IS NOT NULL
)

SELECT * FROM cleaned_support_tickets
