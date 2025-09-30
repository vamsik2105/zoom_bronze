{{ config(
    materialized = 'table',
    pre_hook=["""
        {% if target.name != 'audit_log' %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message
        )
        SELECT
            'bz_users',
            CURRENT_TIMESTAMP(),
            'STARTED',
            'Processing started for bz_users'
        {% endif %}
    """],
    post_hook=["""
        {% if target.name != 'audit_log' %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message,
            row_count
        )
        SELECT
            'bz_users',
            CURRENT_TIMESTAMP(),
            'COMPLETED',
            'Processing completed for bz_users',
            (SELECT COUNT(*) FROM {{ this }})
        {% endif %}
    """]
) }}

-- Extract and transform users data from raw to bronze
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
