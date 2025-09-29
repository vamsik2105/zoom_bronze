{{config(
  materialized = 'table',
  pre_hook=["""
    {% if target.name != 'ci' and this.name != 'audit_log' %}
      INSERT INTO {{ ref('audit_log') }} (
        audit_id,
        model_name,
        process_timestamp,
        process_status,
        error_message,
        record_count
      )
      SELECT
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_participants')),
        'bz_participants',
        CURRENT_TIMESTAMP(),
        'START',
        NULL,
        NULL
    {% endif %}
  """],
  post_hook=["""
    {% if target.name != 'ci' and this.name != 'audit_log' %}
      INSERT INTO {{ ref('audit_log') }} (
        audit_id,
        model_name,
        process_timestamp,
        process_status,
        error_message,
        record_count
      )
      SELECT
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_participants_complete')),
        'bz_participants',
        CURRENT_TIMESTAMP(),
        'COMPLETE',
        NULL,
        (SELECT COUNT(*) FROM {{ this }})
    {% endif %}
  """]
)}}

-- Extract participants data from raw source
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
