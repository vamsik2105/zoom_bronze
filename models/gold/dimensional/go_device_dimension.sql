{{ config(
    materialized='table'
) }}

WITH device_data AS (
    SELECT DISTINCT
        participant_id as device_connection_id,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'si_participants') }}
    WHERE participant_id IS NOT NULL
    AND record_status = 'ACTIVE'
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['device_connection_id']) }} as device_dim_id,
    device_connection_id,
    CAST(NULL AS VARCHAR(255)) as device_type,
    CAST(NULL AS VARCHAR(255)) as operating_system,
    CAST(NULL AS VARCHAR(255)) as application_version,
    CAST(NULL AS VARCHAR(255)) as network_connection_type,
    CAST(NULL AS VARCHAR(255)) as device_category,
    CAST(NULL AS VARCHAR(255)) as platform_family,
    load_date,
    update_date,
    source_system,
    CURRENT_TIMESTAMP() as created_at,
    CURRENT_TIMESTAMP() as updated_at,
    'ACTIVE' as process_status
FROM device_data
