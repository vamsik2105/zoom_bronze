{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, status, message, created_at) SELECT 'bz_support_tickets', CURRENT_TIMESTAMP, 'STARTED', 'Processing bz_support_tickets transformation', CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, status, message, created_at) SELECT 'bz_support_tickets', CURRENT_TIMESTAMP, 'SUCCESS', 'Completed bz_support_tickets transformation', CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for support tickets
WITH source_data AS (
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

cleaned_data AS (
    SELECT 
        -- Direct 1-to-1 mapping from raw to bronze
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        -- Metadata columns with current timestamp
        CURRENT_TIMESTAMP as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
    WHERE ticket_id IS NOT NULL -- Basic data quality check
)

SELECT * FROM cleaned_data
