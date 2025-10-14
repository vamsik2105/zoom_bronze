{{ config(
    materialized='table'
) }}

WITH final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['1']) }} as device_dim_id,
        'DEVICE_001' as device_connection_id,
        'Desktop' as device_type,
        'Windows' as operating_system,
        '5.0.0' as application_version,
        'WiFi' as network_connection_type,
        'Computer' as device_category,
        'Windows' as platform_family,
        CURRENT_DATE() as load_date,
        CURRENT_DATE() as update_date,
        'SYSTEM' as source_system
)

SELECT * FROM final
