{{ config(
    materialized='table'
) }}

WITH default_devices AS (
    SELECT 
        'UNKNOWN_DEVICE' AS device_connection_id,
        'Unknown' AS device_type,
        'Unknown' AS operating_system,
        'Unknown' AS application_version,
        'Unknown' AS network_connection_type,
        'Unknown' AS device_category,
        'Unknown' AS platform_family,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
),

final_transformation AS (
    SELECT 
        CONCAT('DEVICE_', ROW_NUMBER() OVER (ORDER BY device_connection_id)) AS device_dim_id,
        device_connection_id,
        device_type,
        operating_system,
        application_version,
        network_connection_type,
        device_category,
        platform_family,
        load_date,
        update_date,
        source_system
    FROM default_devices
)

SELECT 
    device_dim_id,
    device_connection_id,
    device_type,
    operating_system,
    application_version,
    network_connection_type,
    device_category,
    platform_family,
    load_date,
    update_date,
    source_system
FROM final_transformation
