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
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_feature_usage')),
        'bz_feature_usage',
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
        MD5(CONCAT(CURRENT_TIMESTAMP()::STRING, '-', 'bz_feature_usage_complete')),
        'bz_feature_usage',
        CURRENT_TIMESTAMP(),
        'COMPLETE',
        NULL,
        (SELECT COUNT(*) FROM {{ this }})
    {% endif %}
  """]
)}}

-- Extract feature usage data from raw source
SELECT
  usage_id,
  meeting_id,
  feature_name,
  usage_count,
  usage_date,
  load_timestamp,
  update_timestamp,
  source_system
FROM {{ source('raw', 'feature_usage') }}
