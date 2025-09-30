{{config(
    materialized='table',
    pre_hook=[
      "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, process_status, record_count, error_message) 
       SELECT uuid_string(), 'bz_webinars_1', CURRENT_TIMESTAMP(), 'started', 0, NULL"
    ],
    post_hook=[
      "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, process_status, record_count, error_message) 
       SELECT uuid_string(), 'bz_webinars_1', CURRENT_TIMESTAMP(), 'completed', COUNT(*), NULL FROM {{ this }}"
    ]
)}}

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
