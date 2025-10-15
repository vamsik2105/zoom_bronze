{{ config(
    materialized='table'
) }}

WITH date_range AS (
    SELECT 
        CURRENT_DATE() - 30 AS start_date,
        CURRENT_DATE() + 30 AS end_date
),

date_series AS (
    SELECT 
        DATEADD(DAY, SEQ4(), (SELECT start_date FROM date_range)) AS date_key
    FROM TABLE(GENERATOR(ROWCOUNT => 61))
    WHERE date_key <= (SELECT end_date FROM date_range)
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
        'DBT_SYSTEM' AS source_system,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date
    FROM date_series
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
