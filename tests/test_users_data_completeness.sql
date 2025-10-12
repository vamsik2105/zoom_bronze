/*
  Test Case: TC_BZ_USERS_005
  Description: Verify data completeness between raw and bronze layers
*/

WITH raw_count AS (
    SELECT COUNT(*) as raw_records
    FROM {{ source('raw_zoom', 'users') }}
),
bronze_count AS (
    SELECT COUNT(*) as bronze_records
    FROM {{ ref('bz_users') }}
)
SELECT 
    raw_records,
    bronze_records,
    ABS(raw_records - bronze_records) as record_difference
FROM raw_count
CROSS JOIN bronze_count
WHERE raw_records != bronze_records