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
            'bz_meetings',
            CURRENT_TIMESTAMP(),
            'STARTED',
            'Processing started for bz_meetings'
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
            'bz_meetings',
            CURRENT_TIMESTAMP(),
            'COMPLETED',
            'Processing completed for bz_meetings',
            (SELECT COUNT(*) FROM {{ this }})
        {% endif %}
    """]
) }}

-- Extract and transform meetings data from raw to bronze
SELECT
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'meetings') }}
