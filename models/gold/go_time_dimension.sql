{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, load_date) VALUES ('{{ invocation_id }}', 'go_time_dimension', 'DBT_MODEL', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', 'DBT_CLOUD', CURRENT_DATE())",
    post_hook="UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()), records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), records_failed = 0, update_date = CURRENT_DATE() WHERE execution_id = '{{ invocation_id }}' AND pipeline_name = 'go_time_dimension'"
) }}

-- Gold Time Dimension Table
WITH meeting_dates AS (
    SELECT DISTINCT 
        CAST(start_time AS DATE) AS date_key
    FROM {{ source('silver', 'si_meetings') }}
    WHERE start_time IS NOT NULL
),

webinar_dates AS (
    SELECT DISTINCT 
        CAST(start_time AS DATE) AS date_key
    FROM {{ source('silver', 'si_webinars') }}
    WHERE start_time IS NOT NULL
),

all_dates AS (
    SELECT date_key FROM meeting_dates
    UNION 
    SELECT date_key FROM webinar_dates
),

time_dimension AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['date_key']) }} AS time_dim_id,
        date_key,
        EXTRACT(YEAR FROM date_key) AS year_number,
        EXTRACT(QUARTER FROM date_key) AS quarter_number,
        EXTRACT(MONTH FROM date_key) AS month_number,
        TO_VARCHAR(date_key, 'MMMM') AS month_name,
        EXTRACT(WEEK FROM date_key) AS week_number,
        EXTRACT(DOY FROM date_key) AS day_of_year,
        EXTRACT(DAY FROM date_key) AS day_of_month,
        EXTRACT(DOW FROM date_key) AS day_of_week,
        TO_VARCHAR(date_key, 'DAY') AS day_name,
        CASE WHEN EXTRACT(DOW FROM date_key) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
        FALSE AS is_holiday,
        EXTRACT(YEAR FROM date_key) AS fiscal_year,
        EXTRACT(QUARTER FROM date_key) AS fiscal_quarter,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM_GENERATED' AS source_system
    FROM all_dates
)

SELECT * FROM time_dimension
