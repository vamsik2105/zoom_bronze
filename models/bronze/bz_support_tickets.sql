{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_support_tickets', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_support_tickets', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- Bronze Support Tickets Table
-- Transforms raw support tickets data with data quality checks and audit columns
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
    FROM {{ source('raw_data', 'support_tickets') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(ticket_id, 'UNKNOWN') as ticket_id,
        COALESCE(user_id, 'UNKNOWN') as user_id,
        COALESCE(ticket_type, 'UNKNOWN') as ticket_type,
        COALESCE(resolution_status, 'UNKNOWN') as resolution_status,
        open_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
