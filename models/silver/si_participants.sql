{{
    config(
        materialized='incremental',
        unique_key='participant_id',
        on_schema_change='fail'
    )
}}

-- Silver Participants Transformation with Data Quality Checks
WITH source_data AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        ROW_NUMBER() OVER (
            PARTITION BY participant_id 
            ORDER BY update_timestamp DESC, 
                     load_timestamp DESC,
                     (CASE WHEN meeting_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN join_time IS NOT NULL THEN 1 ELSE 0 END +
                      CASE WHEN leave_time IS NOT NULL THEN 1 ELSE 0 END) DESC
        ) AS row_rank
    FROM {{ source('bronze', 'bz_participants') }}
    WHERE participant_id IS NOT NULL
    
    {% if is_incremental() %}
        AND update_timestamp > (SELECT COALESCE(MAX(update_timestamp), '1900-01-01') FROM {{ this }})
    {% endif %}
),

data_quality_checks AS (
    SELECT 
        *,
        -- Time validation
        CASE 
            WHEN join_time IS NOT NULL AND leave_time IS NOT NULL AND leave_time > join_time THEN 1
            ELSE 0
        END AS time_valid,
        
        -- Meeting reference check
        CASE 
            WHEN meeting_id IS NOT NULL AND TRIM(meeting_id) != '' THEN 1
            ELSE 0
        END AS meeting_valid,
        
        -- Completeness check
        CASE 
            WHEN participant_id IS NOT NULL AND meeting_id IS NOT NULL AND join_time IS NOT NULL AND leave_time IS NOT NULL THEN 1
            ELSE 0
        END AS completeness_check
    FROM source_data
    WHERE row_rank = 1
),

final_data AS (
    SELECT 
        participant_id,
        meeting_id,
        user_id,  -- Can be nullable as per mapping
        join_time,
        leave_time,
        load_timestamp,
        update_timestamp,
        source_system,
        DATE(load_timestamp) AS load_date,
        DATE(update_timestamp) AS update_date,
        ROUND((time_valid + meeting_valid + completeness_check) / 3.0, 2) AS data_quality_score,
        CASE 
            WHEN time_valid = 1 AND meeting_valid = 1 AND completeness_check = 1 THEN 'active'
            ELSE 'error'
        END AS record_status
    FROM data_quality_checks
)

SELECT * FROM final_data
WHERE record_status = 'active'  -- Only include valid records in Silver layer
