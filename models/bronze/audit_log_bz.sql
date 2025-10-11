{{ config(
    materialized='incremental',
    unique_key='audit_id',
    on_schema_change='fail'
) }}

WITH audit_entries AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['source_layer', 'source_table', 'target_layer', 'target_table', 'load_start_time']) }} AS audit_id,
        'RAW' AS source_layer,
        'CUSTOMER' AS source_table,
        'BRONZE' AS target_layer,
        'CUSTOMER' AS target_table,
        'FULL' AS load_type,
        CURRENT_TIMESTAMP() AS load_start_time,
        CURRENT_TIMESTAMP() AS load_end_time,
        (SELECT COUNT(*) FROM {{ source('raw', 'customer') }}) AS record_count_loaded,
        'SUCCESS' AS status,
        NULL AS error_message,
        '{{ invocation_id }}' AS run_id,
        CURRENT_USER() AS created_by,
        CURRENT_TIMESTAMP() AS created_at
    
    UNION ALL
    
    SELECT
        {{ dbt_utils.generate_surrogate_key(['source_layer', 'source_table', 'target_layer', 'target_table', 'load_start_time']) }} AS audit_id,
        'RAW' AS source_layer,
        'ORDERS' AS source_table,
        'BRONZE' AS target_layer,
        'ORDERS' AS target_table,
        'FULL' AS load_type,
        CURRENT_TIMESTAMP() AS load_start_time,
        CURRENT_TIMESTAMP() AS load_end_time,
        (SELECT COUNT(*) FROM {{ source('raw', 'orders') }}) AS record_count_loaded,
        'SUCCESS' AS status,
        NULL AS error_message,
        '{{ invocation_id }}' AS run_id,
        CURRENT_USER() AS created_by,
        CURRENT_TIMESTAMP() AS created_at
    
    UNION ALL
    
    SELECT
        {{ dbt_utils.generate_surrogate_key(['source_layer', 'source_table', 'target_layer', 'target_table', 'load_start_time']) }} AS audit_id,
        'RAW' AS source_layer,
        'REGION' AS source_table,
        'BRONZE' AS target_layer,
        'REGION' AS target_table,
        'FULL' AS load_type,
        CURRENT_TIMESTAMP() AS load_start_time,
        CURRENT_TIMESTAMP() AS load_end_time,
        (SELECT COUNT(*) FROM {{ source('raw', 'region') }}) AS record_count_loaded,
        'SUCCESS' AS status,
        NULL AS error_message,
        '{{ invocation_id }}' AS run_id,
        CURRENT_USER() AS created_by,
        CURRENT_TIMESTAMP() AS created_at
)

SELECT * FROM audit_entries

{% if is_incremental() %}
    WHERE load_start_time > (SELECT MAX(load_start_time) FROM {{ this }})
{% endif %}
