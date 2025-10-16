{{ config(
    materialized='table',
    pre_hook="{% if this.name != 'go_process_audit' %}INSERT INTO {{ ref('go_process_audit') }} (execution_id, pipeline_name, process_type, start_time, status, source_system, target_system, user_executed, server_name, load_date, update_date) SELECT '{{ dbt_utils.generate_surrogate_key([this.name, run_started_at]) }}', 'zoom_customer_analytics', 'go_time_dimension_load', CURRENT_TIMESTAMP(), 'STARTED', 'SILVER', 'GOLD', CURRENT_USER(), 'DBT_CLOUD', CURRENT_DATE(), CURRENT_DATE(){% endif %}",
    post_hook="{% if this.name != 'go_process_audit' %}UPDATE {{ ref('go_process_audit') }} SET end_time = CURRENT_TIMESTAMP(), status = 'COMPLETED', records_processed = (SELECT COUNT(*) FROM {{ this }}), records_successful = (SELECT COUNT(*) FROM {{ this }}), processing_duration_seconds = DATEDIFF('second', start_time, CURRENT_TIMESTAMP()) WHERE execution_id = '{{ dbt_utils.generate_surrogate_key([this.name, run_started_at]) }}'{% endif %}"
) }}

WITH date_spine AS (
    SELECT DISTINCT
        CAST(start_time AS DATE) AS date_key
    FROM {{ source('silver', 'si_meetings') }}
    WHERE start_time IS NOT NULL
      AND record_status = 'ACTIVE'
    
    UNION
    
    SELECT DISTINCT
        CAST(start_time AS DATE) AS date_key
    FROM {{ source('silver', 'si_webinars') }}
    WHERE start_time IS NOT NULL
      AND record_status = 'ACTIVE'
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
        'DERIVED' AS source_system
    FROM date_spine
)

SELECT
    time_dim_id::VARCHAR(50) AS time_dim_id,
    date_key,
    year_number,
    quarter_number,
    month_number,
    month_name::VARCHAR(20) AS month_name,
    week_number,
    day_of_year,
    day_of_month,
    day_of_week,
    day_name::VARCHAR(20) AS day_name,
    is_weekend,
    is_holiday,
    fiscal_year,
    fiscal_quarter,
    load_date,
    update_date,
    source_system::VARCHAR(100) AS source_system
FROM time_dimension
