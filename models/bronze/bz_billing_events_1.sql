{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_billing_events', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_billing_events transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_billing_events', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_billing_events transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for billing events
WITH source_billing_events AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'billing_events') }}
),

-- Data quality checks and transformations
cleaned_billing_events AS (
    SELECT 
        COALESCE(event_id, 'UNKNOWN') as event_id,
        COALESCE(user_id, 'UNKNOWN') as user_id,
        COALESCE(event_type, 'UNKNOWN') as event_type,
        COALESCE(amount, 0) as amount,
        event_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_billing_events
    WHERE event_id IS NOT NULL
)

SELECT * FROM cleaned_billing_events
