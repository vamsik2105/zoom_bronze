{{ config(
    materialized='table',
    schema='bronze',
    tags=['bronze', 'users'],
    pre_hook=[
        "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('raw.users', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, CAST('IN_PROGRESS' AS VARCHAR(50)))"
    ],
    post_hook=[
        "INSERT INTO {{ ref('bz_audit_log') }} (source_table, load_timestamp, processed_by, processing_time, status) VALUES ('raw.users', CURRENT_TIMESTAMP(), CURRENT_USER(), 0, CAST('SUCCESS' AS VARCHAR(50)))"
    ]
) }}

/*
    Bronze Users Model
    
    Purpose: Transform raw user data into the bronze layer with basic validation
    Source: raw.users
    Target: bronze.bz_users
    
    Transformation: 1-to-1 mapping with added metadata
*/

SELECT
    -- Source columns with basic validation
    user_id,
    user_name,
    email,
    company,
    plan_type,
    
    -- Metadata columns
    COALESCE(load_timestamp, CURRENT_TIMESTAMP()) AS load_timestamp,
    CURRENT_TIMESTAMP() AS update_timestamp,
    COALESCE(source_system, 'ZOOM_PLATFORM') AS source_system
    
FROM {{ source('raw_zoom', 'users') }}
