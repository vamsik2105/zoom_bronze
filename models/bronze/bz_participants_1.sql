{{ config(
    materialized='table'
) }}

-- Bronze layer transformation for participants
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
    FROM {{ source('raw', 'participants') }}
),

cleaned_data AS (
    SELECT 
        -- Direct 1-to-1 mapping from raw to bronze
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        -- Metadata columns with current timestamp
        CURRENT_TIMESTAMP as load_timestamp,
        CURRENT_TIMESTAMP as update_timestamp,
        'ZOOM_PLATFORM' as source_system
    FROM source_data
    WHERE participant_id IS NOT NULL -- Basic data quality check
)

SELECT * FROM cleaned_data
