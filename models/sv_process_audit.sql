-- =====================================================
-- AUDIT LOG MODEL - MUST RUN FIRST
-- =====================================================

{{ config(
    materialized='table',
    pre_hook="
        {% if this.name != 'sv_process_audit' %}
            INSERT INTO {{ ref('sv_process_audit') }} (
                execution_id, pipeline_name, start_time, status, 
                source_system, target_system, process_type, 
                load_date, update_date
            ) VALUES (
                '{{ invocation_id }}', 
                '{{ this.name }}', 
                CURRENT_TIMESTAMP(), 
                'RUNNING', 
                'BRONZE', 
                'SILVER', 
                'ETL', 
                CURRENT_DATE(), 
                CURRENT_DATE()
            )
        {% endif %}
    ",
    post_hook="
        {% if this.name != 'sv_process_audit' %}
            UPDATE {{ ref('sv_process_audit') }} 
            SET end_time = CURRENT_TIMESTAMP(),
                status = 'SUCCESS',
                records_processed = (SELECT COUNT(*) FROM {{ this }}),
                records_successful = (SELECT COUNT(*) FROM {{ this }}),
                records_failed = 0,
                processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP())
            WHERE execution_id = '{{ invocation_id }}' 
            AND pipeline_name = '{{ this.name }}'
        {% endif %}
    "
) }}

-- Base audit log structure
SELECT 
    '{{ invocation_id }}' as execution_id,
    'INITIAL_SETUP' as pipeline_name,
    CURRENT_TIMESTAMP() as start_time,
    CURRENT_TIMESTAMP() as end_time,
    'SUCCESS' as status,
    NULL as error_message,
    0 as records_processed,
    0 as records_successful,
    0 as records_failed,
    0 as processing_duration_seconds,
    'SYSTEM' as source_system,
    'SILVER' as target_system,
    'SETUP' as process_type,
    'DBT' as user_executed,
    'DBT_CLOUD' as server_name,
    NULL as memory_usage_mb,
    NULL as cpu_usage_percent,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date

WHERE FALSE -- This ensures no actual records are inserted for the audit table itself
