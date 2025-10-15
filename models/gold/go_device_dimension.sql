{{ config(
    materialized='table',
    pre_hook="INSERT INTO GOLD.go_process_audit (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, load_date) VALUES ('{{ invocation_id }}', 'go_device_dimension', 'TRANSFORMATION', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_DATE())",
    post_hook="UPDATE GOLD.go_process_audit SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM GOLD.go_device_dimension), processing_duration_seconds = 10 WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_device_dimension'"
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
