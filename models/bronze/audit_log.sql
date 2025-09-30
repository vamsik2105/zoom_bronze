{{ config(
    materialized = 'incremental',
    unique_key = 'log_id'
) }}

-- Create audit log table if it doesn't exist
WITH audit_log AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['process_timestamp', 'model_name', 'status']) }} as log_id,
        model_name,
        process_timestamp,
        status,
        message,
        row_count
    FROM (
        -- This is a dummy query that will return zero rows
        -- but establishes the structure of the table
        SELECT
            CAST(NULL AS STRING) as model_name,
            CAST(NULL AS TIMESTAMP_NTZ) as process_timestamp,
            CAST(NULL AS STRING) as status,
            CAST(NULL AS STRING) as message,
            CAST(NULL AS INTEGER) as row_count
        WHERE 1=0
    )
)

SELECT * FROM audit_log
