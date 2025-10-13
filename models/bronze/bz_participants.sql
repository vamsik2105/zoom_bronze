{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_participants', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'STARTED' WHERE '{{ this.name }}' != 'bz_audit_log'",
    post_hook="INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) SELECT 'bz_participants', CURRENT_TIMESTAMP(), 'DBT_SYSTEM', 0, 'COMPLETED' WHERE '{{ this.name }}' != 'bz_audit_log'"
) }}

-- Bronze Participants Table
-- Transforms raw participants data with data quality checks and audit columns
WITH source_data AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system
    FROM {{ source('raw_data', 'participants') }}
),

-- Data quality and cleansing layer
cleansed_data AS (
    SELECT 
        COALESCE(participant_id, 'UNKNOWN') as participant_id,
        COALESCE(meeting_id, 'UNKNOWN') as meeting_id,
        COALESCE(user_id, 'UNKNOWN') as user_id,
        join_time,
        leave_time,
        COALESCE(load_timestamp, CURRENT_TIMESTAMP()) as load_timestamp,
        CURRENT_TIMESTAMP() as update_timestamp,
        COALESCE(source_system, 'ZOOM_PLATFORM') as source_system
    FROM source_data
)

SELECT * FROM cleansed_data
