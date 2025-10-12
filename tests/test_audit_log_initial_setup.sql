/*
  Test Case: TC_BZ_AUDIT_001
  Description: Verify audit log table has correct initial setup record
*/

SELECT 
    record_id,
    source_table,
    status
FROM {{ ref('bz_audit_log') }}
WHERE 
    record_id != 1 
    OR source_table != 'INITIAL_SETUP'
    OR status != 'SUCCESS'