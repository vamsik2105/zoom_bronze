{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_start_time, process_status, process_message, created_at, updated_at) SELECT 'bz_users', CURRENT_TIMESTAMP, 'STARTED', 'Starting bz_users transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'",
    post_hook="INSERT INTO {{ ref('audit_log_1') }} (table_name, process_end_time, process_status, process_message, created_at, updated_at) SELECT 'bz_users', CURRENT_TIMESTAMP, 'COMPLETED', 'Completed bz_users transformation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_1'"
) }}

-- Bronze layer transformation for users
WITH source_users AS (
    SELECT 
        user_id,
        user_name,
        email,
        company,
        plan_type,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw', 'users') }}
),

-- Data quality checks and transformations
cleaned_users AS (
    SELECT 
        COALESCE(user_id, 'UNKNOWN') as user_id,
        COALESCE(user_name, 'UNKNOWN') as user_name,
        COALESCE(email, 'UNKNOWN') as email,
        COALESCE(company, 'UNKNOWN') as company,
        COALESCE(plan_type, 'UNKNOWN') as plan_type,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP) as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_users
    WHERE user_id IS NOT NULL
)

SELECT * FROM cleaned_users
