{{ config(
    materialized='table',
    tags=['bronze', 'meetings'],
    pre_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (source_table, operation_type, process_status, created_at) VALUES ('bz_meetings', 'LOAD_START', 'RUNNING', CURRENT_TIMESTAMP()){% endif %}",
    post_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (source_table, operation_type, record_count, process_status, updated_at) VALUES ('bz_meetings', 'LOAD_COMPLETE', (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', CURRENT_TIMESTAMP()){% endif %}"
) }}

-- Bronze layer meetings table with 1-1 mapping from raw.meetings
SELECT 
    meeting_id,
    host_id,
    meeting_topic,
    start_time,
    end_time,
    duration_minutes,
    load_timestamp,
    update_timestamp,
    source_system,
    -- Audit columns
    'PROCESSED' AS process_status,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS updated_at
FROM {{ source('raw', 'meetings') }}
