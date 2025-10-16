{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, created_at, updated_at) VALUES (UUID_STRING(), 'device_dimension_transformation', 'si_participants', 'go_device_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET process_status = 'COMPLETED', end_time = CURRENT_TIMESTAMP(), records_processed = (SELECT COUNT(*) FROM {{ this }}), updated_at = CURRENT_TIMESTAMP() WHERE process_name = 'device_dimension_transformation' AND process_status = 'STARTED'"
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
    UUID_STRING() as device_dim_id,
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
