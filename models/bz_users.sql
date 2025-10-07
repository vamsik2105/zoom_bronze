-- Simple transformation for users
SELECT
  *
FROM {{ source('raw', 'users') }}
