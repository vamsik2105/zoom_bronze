{{ config(
    materialized='table'
) }}

-- Time Dimension transformation
WITH date_range AS (
    SELECT 
        DATEADD('day', seq4(), '2020-01-01'::date) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 4018)) -- 11 years of dates
    WHERE date_day <= '2030-12-31'::date
),

time_dimension_final AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} AS time_dim_id,
        date_day AS date_key,
        EXTRACT(YEAR FROM date_day) AS year_number,
        EXTRACT(QUARTER FROM date_day) AS quarter_number,
        EXTRACT(MONTH FROM date_day) AS month_number,
        MONTHNAME(date_day) AS month_name,
        EXTRACT(WEEK FROM date_day) AS week_number,
        EXTRACT(DOY FROM date_day) AS day_of_year,
        EXTRACT(DAY FROM date_day) AS day_of_month,
        EXTRACT(DOW FROM date_day) AS day_of_week,
        DAYNAME(date_day) AS day_name,
        CASE WHEN EXTRACT(DOW FROM date_day) IN (0,6) THEN TRUE ELSE FALSE END AS is_weekend,
        FALSE AS is_holiday,
        EXTRACT(YEAR FROM date_day) AS fiscal_year,
        EXTRACT(QUARTER FROM date_day) AS fiscal_quarter,
        CURRENT_DATE() AS load_date,
        CURRENT_DATE() AS update_date,
        'SYSTEM_GENERATED' AS source_system
    FROM date_range
)

SELECT * FROM time_dimension_final
