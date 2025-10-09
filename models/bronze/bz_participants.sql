{{ config(
    materialized='table',
    tags=['bronze', 'participants'],
    pre_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (source_table, operation_type, process_status, created_at) VALUES ('bz_participants', 'LOAD_START', 'RUNNING', CURRENT_TIMESTAMP()){% endif %}",
    post_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (source_table, operation_type, record_count, process_status, updated_at) VALUES ('bz_participants', 'LOAD_COMPLETE', (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', CURRENT_TIMESTAMP()){% endif %}"
) }}

-- Bronze layer participants table with 1-1 mapping from raw.participants
SELECT 
    participant_id,
    meeting_id,
    user_id,
    join_time,
    leave_time,
    load_timestamp,
    update_timestamp,
    source_system,
    -- Audit columns
    'PROCESSED' AS process_status,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS updated_at
FROM {{ source('raw', 'participants') }}
