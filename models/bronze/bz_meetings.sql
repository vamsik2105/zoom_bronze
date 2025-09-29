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
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_meetings')),
        'bz_meetings',
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
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_meetings_complete')),
        'bz_meetings',
        CURRENT_TIMESTAMP(),
        'COMPLETE',
        NULL,
        (SELECT COUNT(*) FROM {{ this }})
    {% endif %}
  """]
)}}

-- Extract meetings data from raw source
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
