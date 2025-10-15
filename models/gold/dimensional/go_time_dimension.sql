{{ config(
    materialized='table'
) }}

WITH silver_meetings_check AS (
    SELECT COUNT(*) as meeting_count
    FROM {{ ref('si_meetings') }}
),

default_dates AS (
    SELECT DISTINCT
        CURRENT_DATE() AS date_key,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    WHERE (SELECT meeting_count FROM silver_meetings_check) = 0
    
    UNION ALL
    
    SELECT DISTINCT
        CURRENT_DATE() - 1 AS date_key,
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    WHERE (SELECT meeting_count FROM silver_meetings_check) = 0
),

silver_dates AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) AS date_key,
        source_system,
        load_date,
        update_date
    FROM {{ ref('si_meetings') }}
    WHERE start_time IS NOT NULL
      AND record_status = 'ACTIVE'
      AND data_quality_score >= 0.8
    
    UNION ALL
    
    SELECT 
        date_key,
        source_system,
        load_date,
        update_date
    FROM default_dates
),

time_calculations AS (
    SELECT 
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
        source_system,
        load_date,
        update_date
    FROM silver_dates
),

final_transformation AS (
    SELECT 
        CONCAT('TIME_', TO_VARCHAR(date_key, 'YYYYMMDD')) AS time_dim_id,
        date_key,
        year_number,
        quarter_number,
        month_number,
        month_name,
        week_number,
        day_of_year,
        day_of_month,
        day_of_week,
        day_name,
        is_weekend,
        is_holiday,
        fiscal_year,
        fiscal_quarter,
        load_date,
        update_date,
        source_system
    FROM time_calculations
)

SELECT 
    time_dim_id,
    date_key,
    year_number,
    quarter_number,
    month_number,
    month_name,
    week_number,
    day_of_year,
    day_of_month,
    day_of_week,
    day_name,
    is_weekend,
    is_holiday,
    fiscal_year,
    fiscal_quarter,
    load_date,
    update_date,
    source_system
FROM final_transformation
