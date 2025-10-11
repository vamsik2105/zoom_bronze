{{
  config(
    materialized='table',
    tags=['bronze', 'region'],
    pre_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'REGION', 'BRONZE', 'REGION_BZ', 'FULL', CURRENT_TIMESTAMP, 'RUNNING', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'",
    post_hook="INSERT INTO {{ ref('audit_log_bz') }} (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, LOAD_END_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'REGION', 'BRONZE', 'REGION_BZ', 'FULL', CURRENT_TIMESTAMP - INTERVAL '1 MINUTE', CURRENT_TIMESTAMP, (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'"
  )
}}

-- Bronze layer transformation for REGION table
-- Transforms raw region data with data quality checks and standardization

WITH source_data AS (
    SELECT 
        region_id,
        region_name,
        country
    FROM {{ source('raw', 'region') }}
),

-- Data quality checks and transformations
transformed_data AS (
    SELECT 
        region_id,
        -- Standardize region name with proper case as per mapping
        INITCAP(TRIM(region_name)) AS region_name,
        -- Standardize country to uppercase as per mapping
        UPPER(TRIM(country)) AS country,
        -- Add audit columns
        CURRENT_TIMESTAMP AS created_at,
        CURRENT_TIMESTAMP AS last_updated,
        -- Add load date for tracking
        CURRENT_DATE() AS load_date,
        -- Add data quality flags
        CASE 
            WHEN region_id IS NULL THEN 'MISSING_ID'
            WHEN region_name IS NULL OR TRIM(region_name) = '' THEN 'MISSING_NAME'
            WHEN country IS NULL OR TRIM(country) = '' THEN 'MISSING_COUNTRY'
            ELSE 'VALID'
        END AS data_quality_status
    FROM source_data
),

-- Filter out invalid records (optional - based on business rules)
final_data AS (
    SELECT 
        region_id,
        region_name,
        country,
        created_at,
        last_updated,
        load_date
    FROM transformed_data
    WHERE data_quality_status = 'VALID'
        AND region_id IS NOT NULL
)

SELECT * FROM final_data
