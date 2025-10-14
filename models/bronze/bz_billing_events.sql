-- Bronze layer transformation for billing events data
-- Transforms raw billing events data into bronze layer with audit tracking

{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_billing_events', CURRENT_TIMESTAMP(), 'dbt', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_billing_events', CURRENT_TIMESTAMP(), 'dbt', DATEDIFF('second', (SELECT MAX(load_timestamp) FROM {{ ref('bz_audit_log') }} WHERE source_table = 'bz_billing_events' AND status = 'STARTED'), CURRENT_TIMESTAMP()), 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- CTE for data validation and cleansing
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
    FROM {{ source('raw', 'billing_events') }}
    WHERE event_id IS NOT NULL -- Basic data quality check
),

-- CTE for adding bronze layer metadata
final_data AS (
    SELECT 
        -- Source columns (1:1 mapping)
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        
        -- Metadata columns
        CURRENT_TIMESTAMP() as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
)

SELECT * FROM final_data