{{ config(
    materialized='incremental',
    unique_key='event_id',
    on_schema_change='fail',
    pre_hook="INSERT INTO {{ ref('si_process_audit') }} (execution_id, pipeline_name, start_time, status, source_system, target_system, process_type, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_billing_events']) }}', 'si_billing_events_transformation', CURRENT_TIMESTAMP(), 'STARTED', 'Bronze', 'Silver', 'ETL', CURRENT_DATE(), CURRENT_DATE() WHERE '{{ this.name }}' != 'si_process_audit'",
    post_hook="UPDATE {{ ref('si_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([invocation_id, 'si_billing_events']) }}' AND '{{ this.name }}' != 'si_process_audit'"
) }}

-- Silver Billing Events Transformation with Data Quality Checks
WITH bronze_billing_events AS (
    SELECT 
        event_id,
        user_id,
        event_type,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY event_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     CASE WHEN event_type IS NOT NULL THEN 1 ELSE 0 END +
                     CASE WHEN amount IS NOT NULL THEN 1 ELSE 0 END DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_billing_events') }}
    WHERE event_id IS NOT NULL
),

deduped_billing_events AS (
    SELECT *
    FROM bronze_billing_events
    WHERE row_rank = 1
),

data_quality_checks AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(event_type)) IN ('SUBSCRIPTION FEE', 'SUBSCRIPTION RENEWAL', 'ADD-ON PURCHASE', 'REFUND') 
            THEN UPPER(TRIM(event_type))
            ELSE 'OTHER'
        END AS event_type_clean,
        amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        -- Data Quality Score Calculation
        (
            CASE WHEN event_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN user_id IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN UPPER(TRIM(event_type)) IN ('SUBSCRIPTION FEE', 'SUBSCRIPTION RENEWAL', 'ADD-ON PURCHASE', 'REFUND') THEN 0.25 ELSE 0 END +
            CASE WHEN amount >= 0 THEN 0.25 ELSE 0 END
        ) AS data_quality_score,
        -- Record Status
        CASE 
            WHEN event_id IS NULL THEN 'ERROR'
            WHEN user_id IS NULL THEN 'ERROR'
            WHEN event_type IS NULL OR TRIM(event_type) = '' THEN 'ERROR'
            WHEN amount < 0 THEN 'ERROR'
            ELSE 'ACTIVE'
        END AS record_status
    FROM deduped_billing_events
),

final_billing_events AS (
    SELECT 
        event_id,
        user_id,
        event_type_clean AS event_type,
        amount,
        event_date,
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
    event_id,
    user_id,
    event_type,
    amount,
    event_date,
    load_timestamp,
    update_timestamp,
    source_system,
    load_date,
    update_date,
    data_quality_score,
    record_status
FROM final_billing_events

{% if is_incremental() %}
    WHERE update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
{% endif %}
