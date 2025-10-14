{{ config(
    materialized='table'
) }}

-- Gold Device Dimension Table
-- Note: Device fields not available in Silver participants, creating default device
WITH default_device AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(["'DEFAULT_DEVICE'"]) }} AS device_dim_id,
        'DEFAULT_DEVICE' AS device_connection_id,
        'Unknown' AS device_type,
        'Unknown' AS operating_system,
        'Unknown' AS application_version,
        'Unknown' AS network_connection_type,
        'Unknown' AS device_category,
        'Unknown' AS platform_family,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM_GENERATED' AS source_system
)

SELECT * FROM default_device
