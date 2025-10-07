-- Bronze layer transformation for licenses data
-- Maps raw license data to the bronze schema with audit columns

{% set start_time = 'CURRENT_TIMESTAMP()' %}

{{ config(
    materialized = 'table',
    pre_hook = """{{ log_table_process_start('bz_licenses') }}""",
    post_hook = """{{ log_table_process_end('bz_licenses', start_time) }}"""
) }}

SELECT
    -- Map source columns to target columns
    License_ID as license_id,
    License_Type as license_type,
    Assigned_To_User_ID as assigned_to_user_id,
    Start_Date as start_date,
    End_Date as end_date,
    -- Add metadata columns
    CURRENT_TIMESTAMP() as load_timestamp,
    CURRENT_TIMESTAMP() as update_timestamp,
    'ZOOM_PLATFORM' as source_system
FROM {{ source('zoom', 'licenses') }}
