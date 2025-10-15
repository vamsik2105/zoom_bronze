{{ config(
    materialized='table',
    pre_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date, update_date, source_system) VALUES (UUID_STRING(), 'go_device_dimension_transform', 'si_participants', 'go_device_dimension', 'STARTED', CURRENT_TIMESTAMP(), NULL, 0, NULL, CURRENT_DATE(), CURRENT_DATE(), 'DBT_TRANSFORM'){% endif %}",
    post_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (process_id, process_name, source_table, target_table, process_status, start_time, end_time, records_processed, error_message, load_date, update_date, source_system) VALUES (UUID_STRING(), 'go_device_dimension_transform', 'si_participants', 'go_device_dimension', 'COMPLETED', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), (SELECT COUNT(*) FROM {{ this }}), NULL, CURRENT_DATE(), CURRENT_DATE(), 'DBT_TRANSFORM'){% endif %}"
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
        UUID_STRING() AS device_dim_id,
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
