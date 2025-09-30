{{config(
    materialized='table',
    pre_hook=[
      "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, process_status, record_count, error_message) 
       SELECT uuid_string(), 'bz_licenses_1', CURRENT_TIMESTAMP(), 'started', 0, NULL"
    ],
    post_hook=[
      "INSERT INTO {{ ref('audit_log') }} (audit_id, model_name, process_timestamp, process_status, record_count, error_message) 
       SELECT uuid_string(), 'bz_licenses_1', CURRENT_TIMESTAMP(), 'completed', COUNT(*), NULL FROM {{ this }}"
    ]
)}}

-- Extract and transform licenses data from raw to bronze
SELECT
    license_id,
    license_type,
    assigned_to_user_id,
    start_date,
    end_date,
    load_timestamp,
    update_timestamp,
    source_system
FROM {{ source('raw', 'licenses') }}
