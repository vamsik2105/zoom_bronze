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
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
),

device_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['participant_id']) }} as device_dim_id,
        participant_id as device_connection_id,
        'Unknown' as device_type,              -- Not available in Silver
        'Unknown' as operating_system,         -- Not available in Silver
        'Unknown' as application_version,      -- Not available in Silver
        'Unknown' as network_connection_type,  -- Not available in Silver
        'Unknown' as device_category,          -- Not available in Silver
        'Unknown' as platform_family,          -- Not available in Silver
        load_date,
        update_date,
        source_system,
        CURRENT_TIMESTAMP() as created_at,
        CURRENT_TIMESTAMP() as updated_at,
        'SUCCESS' as process_status
    FROM silver_participants
)

SELECT * FROM device_dimension
