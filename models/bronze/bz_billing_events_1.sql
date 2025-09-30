{{config(
    materialized='table',
    pre_hook=[
      "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, process_status, record_count, error_message) 
       SELECT uuid_string(), 'bz_billing_events_1', CURRENT_TIMESTAMP(), 'started', 0, NULL"
    ],
    post_hook=[
      "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, process_status, record_count, error_message) 
       SELECT uuid_string(), 'bz_billing_events_1', CURRENT_TIMESTAMP(), 'completed', COUNT(*), NULL FROM {{ this }}"
    ]
)}}

-- Extract and transform billing events data from raw to bronze
SELECT
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'billing_events') }}
