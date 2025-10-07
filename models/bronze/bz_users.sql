-- Bronze layer transformation for users data
-- Maps raw user data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_users') }}""",
    post_hook = """{{ log_table_process_end('bz_users', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    User_ID as user_id,
    User_Name as user_name,
    Email as email,
    Company as company,
    Plan_Type as plan_type,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'users') }}
