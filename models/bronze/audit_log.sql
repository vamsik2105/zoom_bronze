{{ config(
    materialized='table',
    schema='bronze'
) }}

-- Create audit log table if it doesn't exist
WITH audit_log AS (
    SELECT
        MD5(model_name || '-' || TO_CHAR(process_timestamp, 'YYYY-MM-DD HH24:MI:SS.FF')) as audit_id,
        model_name,
        process_timestamp,
        status,
        message
    FROM (
        -- This is just to initialize the table with a dummy record
        -- It will be filtered out in the final SELECT
        SELECT
            'INIT' as model_name,
            CURRENT_TIMESTAMP() as process_timestamp,
            'INIT' as status,
            'Audit log initialization' as message
    )
    WHERE 1=0  -- This ensures no records are actually inserted from this CTE
)

SELECT * FROM audit_log
