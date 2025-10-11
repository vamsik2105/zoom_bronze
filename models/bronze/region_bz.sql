{{ config(
    materialized='table',
    pre_hook="INSERT INTO {{ target.schema }}.audit_log_bz (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'REGION', 'BRONZE', 'REGION_BZ', 'FULL', CURRENT_TIMESTAMP, 0, 'STARTED', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'",
    post_hook="INSERT INTO {{ target.schema }}.audit_log_bz (SOURCE_LAYER, SOURCE_TABLE, TARGET_LAYER, TARGET_TABLE, LOAD_TYPE, LOAD_START_TIME, LOAD_END_TIME, RECORD_COUNT_LOADED, STATUS, RUN_ID, CREATED_BY, CREATED_AT) SELECT 'RAW', 'REGION', 'BRONZE', 'REGION_BZ', 'FULL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', '{{ invocation_id }}', CURRENT_USER(), CURRENT_TIMESTAMP WHERE '{{ this.name }}' != 'audit_log_bz'"
) }}

/*
    Bronze Layer Transformation for Region Data
    Source: RAW.REGION
    Target: BRONZE.REGION_BZ
    
    Transformations Applied:
    - region_name: Apply proper case formatting (initcap)
    - country: Convert to uppercase
    - Add audit columns for tracking
*/

WITH source_data AS (
    SELECT 
        region_id,
        region_name,
        country
    FROM {{ source('raw_data', 'region') }}
),

data_quality_checks AS (
    SELECT 
        *,
        CASE 
            WHEN region_id IS NULL THEN 'REGION_ID_NULL'
            WHEN region_name IS NULL OR TRIM(region_name) = '' THEN 'REGION_NAME_INVALID'
            WHEN country IS NULL OR TRIM(country) = '' THEN 'COUNTRY_INVALID'
            ELSE 'VALID'
        END as data_quality_flag
    FROM source_data
),

transformed_data AS (
    SELECT 
        region_id,
        INITCAP(TRIM(region_name)) as region_name,
        UPPER(TRIM(country)) as country,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as last_updated,
        CURRENT_DATE() as load_date,
        data_quality_flag
    FROM data_quality_checks
    WHERE data_quality_flag = 'VALID'  -- Only load valid records
)

SELECT 
    region_id,
    region_name,
    country,
    created_at,
    last_updated,
    load_date
FROM transformed_data
