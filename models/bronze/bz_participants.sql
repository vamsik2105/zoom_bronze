-- Bronze layer transformation for participants data
-- Maps raw participant data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_participants') }}""",
    post_hook = """{{ log_table_process_end('bz_participants', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    Participant_ID as participant_id,
    Meeting_ID as meeting_id,
    User_ID as user_id,
    Join_Time as join_time,
    Leave_Time as leave_time,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'participants') }}
