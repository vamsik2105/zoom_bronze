{{ config(
    materialized='table',
    pre_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, server_name, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([this.name, run_started_at]) }}', 'zoom_customer_analytics', 'go_device_dimension_load', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_USER(), 'DBT_CLOUD', CURRENT_DATE(), CURRENT_DATE(){% endif %}",
    post_hook="{% if this.name != 'go_process_audit' %}UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([this.name, run_started_at]) }}'{% endif %}"
) }}

WITH device_base AS (
    SELECT DISTINCT
        'UNKNOWN' AS device_connection_id,
        'Desktop' AS device_type,
        'Windows' AS operating_system,
        '1.0.0' AS application_version,
        'WiFi' AS network_connection_type,
        'Computer' AS device_category,
        'Windows' AS platform_family,
        load_date,
        update_date,
        source_system
    FROM {{ source('silver', 'si_participants') }}
    WHERE record_status = 'ACTIVE'
    LIMIT 1
),

device_dimension AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['device_connection_id', 'device_type']) }} AS device_dim_id,
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
    FROM device_base
)

SELECT
    device_dim_id::VARCHAR(50) AS device_dim_id,
    device_connection_id::VARCHAR(50) AS device_connection_id,
    device_type::VARCHAR(100) AS device_type,
    operating_system::VARCHAR(100) AS operating_system,
    application_version::VARCHAR(50) AS application_version,
    network_connection_type::VARCHAR(50) AS network_connection_type,
    device_category::VARCHAR(50) AS device_category,
    platform_family::VARCHAR(50) AS platform_family,
    load_date,
    update_date,
    source_system::VARCHAR(100) AS source_system
FROM device_dimension
