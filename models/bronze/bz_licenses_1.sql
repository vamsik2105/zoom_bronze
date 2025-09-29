{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_licenses', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_licenses transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_licenses', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_licenses transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for licenses
WITH source_licenses AS (
    SELECT 
        license_id,
        license_type,
        assigned_to_user_id,
        start_date,
        end_date,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'licenses') }}
),

-- Data quality checks and transformations
cleaned_licenses AS (
    SELECT 
        COALESCE(license_id, 'UNKNOWN') as license_id,
        COALESCE(license_type, 'UNKNOWN') as license_type,
        COALESCE(assigned_to_user_id, 'UNKNOWN') as assigned_to_user_id,
        start_date,
        end_date,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_licenses
    WHERE license_id IS NOT NULL
)

SELECT * FROM cleaned_licenses
