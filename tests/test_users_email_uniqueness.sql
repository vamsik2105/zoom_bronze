/*
  Test Case: TC_BZ_USERS_009
  Description: Check for duplicate email addresses
*/

SELECT 
    email,
    COUNT(*) as email_count
FROM {{ ref('bz_users') }}
WHERE email IS NOT NULL
GROUP BY email
HAVING COUNT(*) > 1