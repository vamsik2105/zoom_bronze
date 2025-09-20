{{ config(
    materialized='incremental',
    unique_key='audit_id',
    schema='bronze',
    tags=['audit', 'logging']
) }}

/*
================================================================================
DBT Model: audit_log
Project: Zoom_Customer_Analytics
Layer: Bronze - Audit
Description: Centralized audit logging for all bronze layer transformations
Author: Data Engineering Team
================================================================================
*/

WITH audit_entries AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['table_name', 'process_name', 'timestamp']) }} AS audit_id,
        table_name,
        process_name,
        status,
        timestamp,
        '{{ invocation_id }}' AS dbt_run_id,
        CURRENT_TIMESTAMP() AS created_at
    FROM (
        VALUES 
        ('customer_details_brz', 'bronze_transformation', 'INITIALIZED', CURRENT_TIMESTAMP())
    ) AS t(table_name, process_name, status, timestamp)
    
    {% if is_incremental() %}
        WHERE timestamp > (SELECT MAX(timestamp) FROM {{ this }})
    {% endif %}
)

SELECT * FROM audit_entries