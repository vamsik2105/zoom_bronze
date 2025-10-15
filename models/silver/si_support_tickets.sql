{{ config(
    materialized='incremental',
    unique_key='ticket_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_support_tickets']) }}', 'si_support_tickets_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_support_tickets']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Support Tickets Transformation with Data Quality Checks
WITH bronze_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type,
        resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY ticket_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     CASE WHEN ticket_type IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN resolution_status IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_support_tickets') }}
    WHERE ticket_id IS NOT NULL
),

deduped_support_tickets AS (
    SELECT *
    FROM bronze_support_tickets
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        ticket_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(ticket_type)) IN ('AUDIO ISSUE', 'VIDEO ISSUE', 'CONNECTIVITY', 'BILLING INQUIRY', 'FEATURE REQUEST', 'ACCOUNT ACCESS') 
            THEN UPPER(TRIM(ticket_type))
            ELSE 'OTHER'
        END AS ticket_type_clean,
        CASE 
            WHEN UPPER(TRIM(resolution_status)) IN ('OPEN', 'IN PROGRESS', 'PENDING CUSTOMER', 'CLOSED', 'RESOLVED') 
            THEN UPPER(TRIM(resolution_status))
            ELSE 'OPEN'
        END AS resolution_status_clean,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN ticket_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN user_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN UPPER(TRIM(ticket_type)) IN ('AUDIO ISSUE', 'VIDEO ISSUE', 'CONNECTIVITY', 'BILLING INQUIRY', 'FEATURE REQUEST', 'ACCOUNT ACCESS') THEN 0.25 ELSE 0 END +
            CASE WHEN UPPER(TRIM(resolution_status)) IN ('OPEN', 'IN PROGRESS', 'PENDING CUSTOMER', 'CLOSED', 'RESOLVED') THEN 0.25 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN ticket_id IS NULL THEN 'ERROR'
            WHEN user_id IS NULL THEN 'ERROR'
            WHEN ticket_type IS NULL OR TRIM(ticket_type) = '' THEN 'ERROR'
            WHEN resolution_status IS NULL OR TRIM(resolution_status) = '' THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_support_tickets
),

final_support_tickets AS (
    SELECT 
        ticket_id,
        user_id,
        ticket_type_clean AS ticket_type,
        resolution_status_clean AS resolution_status,
        open_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        data_quality_score,
        record_status
    FROM data_quality_checks
    WHERE record_status = 'ACTIVE'  -- Only pass clean records to Silver
)

SELECT 
    ticket_id,
    user_id,
    ticket_type,
    resolution_status,
    open_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM final_support_tickets

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
