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
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_users')),
        'bz_users',
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
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_users_complete')),
        'bz_users',
        CURRENT_TIMESTAMP(),
        'COMPLETE',
        NULL,
        (SELECT COUNT(*) FROM {{ this }})
    {% endif %}
  """]
)}}

-- Extract users data from raw source
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
