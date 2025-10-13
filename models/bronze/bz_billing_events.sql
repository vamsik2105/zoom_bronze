{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_billing_events', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_billing_events', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- Bronze Billing Events Table
-- Transforms raw billing events data with data quality checks and audit columns
WITH source_data AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw_zoom', 'billing_events') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(event_id, 'UNKNOWN') as event_id,
        COALESCE(user_id, 'UNKNOWN') as user_id,
        COALESCE(event_type, 'UNKNOWN') as event_type,
        COALESCE(amount, 0) as amount,
        event_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
