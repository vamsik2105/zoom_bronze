{{
    config(
        materialized='incremental',
        unique_key='meeting_id',
        on_schema_change='fail'
    )
}}

-- Silver Meetings Transformation with Data Quality Checks
WITH source_data AS (
    SELECT 
        meeting_id,
        host_id,
        meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY meeting_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     (CASE WHEN host_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN meeting_topic IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN start_time IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN end_time IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_meetings') }}
    WHERE meeting_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- Time validation
        CASE 
            WHEN start_time IS NOT NULL AND end_time IS NOT NULL AND end_time > start_time THEN 1
            ELSE 0
        END AS time_valid,
        
        -- Duration validation
        CASE 
            WHEN duration_minutes IS NOT NULL AND duration_minutes > 0 AND duration_minutes <= 1440 THEN 1
            ELSE 0
        END AS duration_valid,
        
        -- Host reference check
        CASE 
            WHEN host_id IS NOT NULL AND TRIM(host_id) != '' THEN 1
            ELSE 0
        END AS host_valid,
        
        -- Completeness check
        CASE 
            WHEN meeting_id IS NOT NULL AND host_id IS NOT NULL AND start_time IS NOT NULL AND end_time IS NOT NULL THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        meeting_id,
        host_id,
        CASE 
            WHEN TRIM(meeting_topic) = '' OR meeting_topic IS NULL THEN '000'
            ELSE TRIM(meeting_topic)
        END AS meeting_topic,
        start_time,
        end_time,
        duration_minutes,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((time_valid + duration_valid + host_valid + completeness_check) / 4.0, 2) AS data_quality_score,
        CASE 
            WHEN time_valid = 1 AND duration_valid = 1 AND host_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
