{{ config(
    materialized='table'
) }}

-- Gold Device Dimension Table
-- Creates device dimension with default values since device info not available in Silver

WITH silver_participants AS (
    SELECT DISTINCT
        participant_id,
        source_system,
        load_date,
        update_date
    FROM SILVER.si_participants
    WHERE record_status = 'ACTIVE'
),

device_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['participant_id']) }} as device_dim_id,
        participant_id as device_connection_id,
        'Unknown' as device_type,
        'Unknown' as operating_system,
        'Unknown' as application_version,
        'Unknown' as network_connection_type,
        'Unknown' as device_category,
        'Unknown' as platform_family,
        load_date,
        update_date,
        source_system
    FROM silver_participants
)

SELECT * FROM device_dimension
