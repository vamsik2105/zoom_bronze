-- Bronze layer transformation for users data

{{ config(
    materialized = 'table',
    tags = ['bronze'],
    pre_hook = "{{ log_audit_start('bz_users') }}",
    post_hook = "{{ log_audit_end('bz_users', True) }}"
) }}

SELECT
    -- Direct 1:1 mapping from source
    user_id,
    user_name,
    email,
    company,
    plan_type,
    -- Metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('raw', 'users') }}
