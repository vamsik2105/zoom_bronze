/*
  Test Case: TC_BZ_USERS_003
  Description: Verify update_timestamp is greater than or equal to load_timestamp
*/

SELECT 
    user_id,
    load_timestamp,
    update_timestamp
FROM {{ ref('bz_users') }}
WHERE update_timestamp < load_timestamp