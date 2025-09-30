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
            'bz_support_tickets',
            CURRENT_TIMESTAMP(),
            'STARTED',
            'Processing started for bz_support_tickets'
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
            'bz_support_tickets',
            CURRENT_TIMESTAMP(),
            'COMPLETED',
            'Processing completed for bz_support_tickets',
            (SELECT COUNT(*) FROM {{ this }})
        {% endif %}
    """]
) }}

-- Extract and transform support tickets data from raw to bronze
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
