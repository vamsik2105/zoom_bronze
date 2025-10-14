{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, load_date) VALUES ('{{ invocation_id }}', 'go_device_dimension', 'DBT_MODEL', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', 'DBT_CLOUD', CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), records_failed = 0, update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_device_dimension'"
) }}

-- Gold Device Dimension Table
-- Note: Device fields not available in Silver participants, creating default device
WITH default_device AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['"DEFAULT_DEVICE"']) }} AS device_dim_id,
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
