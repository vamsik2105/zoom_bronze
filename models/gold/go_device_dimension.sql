{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) SELECT '{{ invocation_id }}_device_dim', 'Device Dimension Transform', 'Dimension Build', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE() WHERE '{{ this.name }}' != 'go_process_audit'",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}_device_dim' AND status = 'STARTED' AND '{{ this.name }}' != 'go_process_audit'"
) }}

WITH device_data AS (
    SELECT DISTINCT
        participant_id,
        source_system,
        load_date,
        update_date
    FROM {{ source('silver', 'si_participants') }}
    WHERE participant_id IS NOT NULL
        AND record_status = 'ACTIVE'
),

device_dimension_prep AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['participant_id']) }} AS device_dim_id,
        participant_id AS device_connection_id,
        CAST(NULL AS VARCHAR(100)) AS device_type,
        CAST(NULL AS VARCHAR(100)) AS operating_system,
        CAST(NULL AS VARCHAR(50)) AS application_version,
        CAST(NULL AS VARCHAR(50)) AS network_connection_type,
        CAST(NULL AS VARCHAR(50)) AS device_category,
        CAST(NULL AS VARCHAR(50)) AS platform_family,
        load_date,
        update_date,
        source_system
    FROM device_data
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
FROM device_dimension_prep
