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
            'bz_webinars',
            CURRENT_TIMESTAMP(),
            'STARTED',
            'Processing started for bz_webinars'
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
            'bz_webinars',
            CURRENT_TIMESTAMP(),
            'COMPLETED',
            'Processing completed for bz_webinars',
            (SELECT COUNT(*) FROM {{ this }})
        {% endif %}
    """]
) }}

-- Extract and transform webinars data from raw to bronze
SELECT
    webinar_id,
    host_id,
    webinar_topic,
    start_time,
    end_time,
    registrants,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'webinars') }}
