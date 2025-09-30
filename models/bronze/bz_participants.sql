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
            'bz_participants',
            CURRENT_TIMESTAMP(),
            'STARTED',
            'Processing started for bz_participants'
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
            'bz_participants',
            CURRENT_TIMESTAMP(),
            'COMPLETED',
            'Processing completed for bz_participants',
            (SELECT COUNT(*) FROM {{ this }})
        {% endif %}
    """]
) }}

-- Extract and transform participants data from raw to bronze
SELECT
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'participants') }}
