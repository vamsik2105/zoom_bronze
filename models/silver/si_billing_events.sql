{{
    config(
        materialized='incremental',
        unique_key='event_id',
        on_schema_change='fail'
    )
}}

-- Silver Billing Events Transformation with Data Quality Checks
WITH source_data AS (
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
                     (CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN event_type IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN amount IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN event_date IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_billing_events') }}
    WHERE event_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- Event type validation
        CASE 
            WHEN UPPER(TRIM(event_type)) IN ('SUBSCRIPTION FEE', 'SUBSCRIPTION RENEWAL', 'ADD-ON PURCHASE', 'REFUND') THEN 1
            ELSE 0
        END AS event_type_valid,
        
        -- Amount validation
        CASE 
            WHEN amount IS NOT NULL AND amount >= 0 THEN 1
            ELSE 0
        END AS amount_valid,
        
        -- User reference check
        CASE 
            WHEN user_id IS NOT NULL AND TRIM(user_id) != '' THEN 1
            ELSE 0
        END AS user_valid,
        
        -- Completeness check
        CASE 
            WHEN event_id IS NOT NULL AND user_id IS NOT NULL AND event_type IS NOT NULL 
                 AND amount IS NOT NULL AND event_date IS NOT NULL THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        event_id,
        user_id,
        CASE 
            WHEN UPPER(TRIM(event_type)) IN ('SUBSCRIPTION FEE', 'SUBSCRIPTION RENEWAL', 'ADD-ON PURCHASE', 'REFUND') 
                 THEN UPPER(TRIM(event_type))
            ELSE 'OTHER'
        END AS event_type,
        COALESCE(amount, 0.00) AS amount,
        event_date,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((event_type_valid + amount_valid + user_valid + completeness_check) / 4.0, 2) AS data_quality_score,
        CASE 
            WHEN event_type_valid = 1 AND amount_valid = 1 AND user_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
