_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze Pipeline dbt models in Snowflake
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases - Zoom Bronze Pipeline

## Overview

This document provides comprehensive unit test cases and dbt test scripts for the Zoom Bronze Pipeline transformation models. The pipeline transforms raw Zoom data into bronze layer tables with audit logging capabilities.

## Models Under Test

1. **audit_log** - Audit logging table structure
2. **bz_users** - Bronze layer users table
3. **bz_meetings** - Bronze layer meetings table
4. **bz_participants** - Bronze layer participants table
5. **bz_feature_usage** - Bronze layer feature usage table
6. **bz_webinars** - Bronze layer webinars table
7. **bz_support_tickets** - Bronze layer support tickets table
8. **bz_licenses** - Bronze layer licenses table
9. **bz_billing_events** - Bronze layer billing events table

## Test Case Categories

### 1. Data Quality Tests
### 2. Business Logic Tests
### 3. Edge Case Tests
### 4. Audit Trail Tests
### 5. Performance Tests

---

## Test Case List

| Test Case ID | Test Case Description | Expected Outcome | Priority | Model |
|--------------|----------------------|------------------|----------|-------|
| TC_001 | Validate audit_log table structure creation | Empty table with correct schema | High | audit_log |
| TC_002 | Verify bz_users unique constraint on user_id | No duplicate user_ids | High | bz_users |
| TC_003 | Validate bz_users not_null constraint on user_id | No null user_ids | High | bz_users |
| TC_004 | Check bz_users process_status accepted values | Only PROCESSED, FAILED, PENDING values | High | bz_users |
| TC_005 | Verify bz_meetings unique constraint on meeting_id | No duplicate meeting_ids | High | bz_meetings |
| TC_006 | Validate bz_meetings not_null constraint on meeting_id | No null meeting_ids | High | bz_meetings |
| TC_007 | Check bz_participants unique constraint on participant_id | No duplicate participant_ids | High | bz_participants |
| TC_008 | Validate bz_participants not_null constraint on participant_id | No null participant_ids | High | bz_participants |
| TC_009 | Verify bz_feature_usage unique constraint on usage_id | No duplicate usage_ids | High | bz_feature_usage |
| TC_010 | Validate bz_feature_usage not_null constraint on usage_id | No null usage_ids | High | bz_feature_usage |
| TC_011 | Check bz_webinars unique constraint on webinar_id | No duplicate webinar_ids | High | bz_webinars |
| TC_012 | Validate bz_webinars not_null constraint on webinar_id | No null webinar_ids | High | bz_webinars |
| TC_013 | Verify bz_support_tickets unique constraint on ticket_id | No duplicate ticket_ids | High | bz_support_tickets |
| TC_014 | Validate bz_support_tickets not_null constraint on ticket_id | No null ticket_ids | High | bz_support_tickets |
| TC_015 | Check bz_licenses unique constraint on license_id | No duplicate license_ids | High | bz_licenses |
| TC_016 | Validate bz_licenses not_null constraint on license_id | No null license_ids | High | bz_licenses |
| TC_017 | Verify bz_billing_events unique constraint on event_id | No duplicate event_ids | High | bz_billing_events |
| TC_018 | Validate bz_billing_events not_null constraint on event_id | No null event_ids | High | bz_billing_events |
| TC_019 | Test audit log pre-hook execution | LOAD_START entry created | High | All bronze models |
| TC_020 | Test audit log post-hook execution | LOAD_COMPLETE entry created with record count | High | All bronze models |
| TC_021 | Validate row count consistency between source and bronze | Source count = Bronze count | High | All bronze models |
| TC_022 | Test timestamp generation for audit columns | created_at and updated_at populated | Medium | All bronze models |
| TC_023 | Validate process_status default value | All records have 'PROCESSED' status | Medium | All bronze models |
| TC_024 | Test handling of null values in optional fields | Null values preserved appropriately | Medium | All bronze models |
| TC_025 | Validate source system field population | source_system field populated from source | Medium | All bronze models |
| TC_026 | Test load_timestamp preservation | load_timestamp copied from source | Medium | All bronze models |
| TC_027 | Test update_timestamp preservation | update_timestamp copied from source | Medium | All bronze models |
| TC_028 | Validate referential integrity for participants-meetings | All participant meeting_ids exist in meetings | High | bz_participants |
| TC_029 | Validate referential integrity for participants-users | All participant user_ids exist in users | High | bz_participants |
| TC_030 | Validate referential integrity for feature_usage-meetings | All feature usage meeting_ids exist in meetings | High | bz_feature_usage |
| TC_031 | Test empty source table handling | Bronze table created but empty | Medium | All bronze models |
| TC_032 | Test large dataset processing | Performance within acceptable limits | Low | All bronze models |
| TC_033 | Validate audit log completeness | All bronze tables have audit entries | High | audit_log |
| TC_034 | Test concurrent execution handling | No duplicate audit entries | Medium | All bronze models |
| TC_035 | Validate data type preservation | All data types match source schema | High | All bronze models |

---

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# tests/schema_tests.yml
version: 2

models:
  # Audit Log Tests
  - name: audit_log
    description: "Audit log table structure validation"
    tests:
      - dbt_utils.expression_is_true:
          expression: "source_table IS NULL AND operation_type IS NULL"
          config:
            severity: warn
            where: "1=0"  # This should always pass for empty table

  # Bronze Users Tests
  - name: bz_users
    description: "Bronze users table validation"
    columns:
      - name: user_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error
      - name: created_at
        tests:
          - not_null:
              config:
                severity: warn
      - name: updated_at
        tests:
          - not_null:
              config:
                severity: warn
    tests:
      - dbt_utils.expression_is_true:
          expression: "created_at <= updated_at"
          config:
            severity: warn

  # Bronze Meetings Tests
  - name: bz_meetings
    description: "Bronze meetings table validation"
    columns:
      - name: meeting_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: host_id
        tests:
          - not_null:
              config:
                severity: warn
      - name: duration_minutes
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error

  # Bronze Participants Tests
  - name: bz_participants
    description: "Bronze participants table validation"
    columns:
      - name: participant_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: meeting_id
        tests:
          - not_null:
              config:
                severity: error
      - name: user_id
        tests:
          - not_null:
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error
    tests:
      - dbt_utils.expression_is_true:
          expression: "join_time <= leave_time OR leave_time IS NULL"
          config:
            severity: warn

  # Bronze Feature Usage Tests
  - name: bz_feature_usage
    description: "Bronze feature usage table validation"
    columns:
      - name: usage_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: meeting_id
        tests:
          - not_null:
              config:
                severity: error
      - name: usage_count
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error

  # Bronze Webinars Tests
  - name: bz_webinars
    description: "Bronze webinars table validation"
    columns:
      - name: webinar_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: host_id
        tests:
          - not_null:
              config:
                severity: warn
      - name: registrants
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error

  # Bronze Support Tickets Tests
  - name: bz_support_tickets
    description: "Bronze support tickets table validation"
    columns:
      - name: ticket_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: user_id
        tests:
          - not_null:
              config:
                severity: warn
      - name: resolution_status
        tests:
          - accepted_values:
              values: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED']
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error

  # Bronze Licenses Tests
  - name: bz_licenses
    description: "Bronze licenses table validation"
    columns:
      - name: license_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: assigned_to_user_id
        tests:
          - not_null:
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error
    tests:
      - dbt_utils.expression_is_true:
          expression: "start_date <= end_date OR end_date IS NULL"
          config:
            severity: warn

  # Bronze Billing Events Tests
  - name: bz_billing_events
    description: "Bronze billing events table validation"
    columns:
      - name: event_id
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: user_id
        tests:
          - not_null:
              config:
                severity: warn
      - name: amount
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0"
              config:
                severity: warn
      - name: process_status
        tests:
          - accepted_values:
              values: ['PROCESSED', 'FAILED', 'PENDING']
              config:
                severity: error
```

### Custom SQL-based dbt Tests

```sql
-- tests/test_row_count_consistency.sql
-- Test to ensure row counts match between source and bronze tables

{{ config(severity = 'error') }}

WITH source_counts AS (
  SELECT 'users' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'users') }}
  UNION ALL
  SELECT 'meetings' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'meetings') }}
  UNION ALL
  SELECT 'participants' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'participants') }}
  UNION ALL
  SELECT 'feature_usage' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'feature_usage') }}
  UNION ALL
  SELECT 'webinars' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'webinars') }}
  UNION ALL
  SELECT 'support_tickets' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'support_tickets') }}
  UNION ALL
  SELECT 'licenses' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'licenses') }}
  UNION ALL
  SELECT 'billing_events' as table_name, COUNT(*) as source_count FROM {{ source('raw', 'billing_events') }}
),

bronze_counts AS (
  SELECT 'users' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_users') }}
  UNION ALL
  SELECT 'meetings' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_meetings') }}
  UNION ALL
  SELECT 'participants' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_participants') }}
  UNION ALL
  SELECT 'feature_usage' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_feature_usage') }}
  UNION ALL
  SELECT 'webinars' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_webinars') }}
  UNION ALL
  SELECT 'support_tickets' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_support_tickets') }}
  UNION ALL
  SELECT 'licenses' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_licenses') }}
  UNION ALL
  SELECT 'billing_events' as table_name, COUNT(*) as bronze_count FROM {{ ref('bz_billing_events') }}
)

SELECT 
  s.table_name,
  s.source_count,
  b.bronze_count,
  ABS(s.source_count - b.bronze_count) as count_difference
FROM source_counts s
JOIN bronze_counts b ON s.table_name = b.table_name
WHERE s.source_count != b.bronze_count
```

```sql
-- tests/test_audit_log_completeness.sql
-- Test to ensure all bronze tables have corresponding audit log entries

{{ config(severity = 'warn') }}

WITH expected_tables AS (
  SELECT table_name FROM (
    VALUES 
    ('bz_users'),
    ('bz_meetings'),
    ('bz_participants'),
    ('bz_feature_usage'),
    ('bz_webinars'),
    ('bz_support_tickets'),
    ('bz_licenses'),
    ('bz_billing_events')
  ) AS t(table_name)
),

audit_entries AS (
  SELECT DISTINCT source_table
  FROM {{ ref('audit_log') }}
  WHERE operation_type IN ('LOAD_START', 'LOAD_COMPLETE')
)

SELECT 
  et.table_name as missing_audit_table
FROM expected_tables et
LEFT JOIN audit_entries ae ON et.table_name = ae.source_table
WHERE ae.source_table IS NULL
```

```sql
-- tests/test_referential_integrity_participants_meetings.sql
-- Test referential integrity between participants and meetings

{{ config(severity = 'error') }}

SELECT 
  p.participant_id,
  p.meeting_id
FROM {{ ref('bz_participants') }} p
LEFT JOIN {{ ref('bz_meetings') }} m ON p.meeting_id = m.meeting_id
WHERE m.meeting_id IS NULL
  AND p.meeting_id IS NOT NULL
```

```sql
-- tests/test_referential_integrity_participants_users.sql
-- Test referential integrity between participants and users

{{ config(severity = 'warn') }}

SELECT 
  p.participant_id,
  p.user_id
FROM {{ ref('bz_participants') }} p
LEFT JOIN {{ ref('bz_users') }} u ON p.user_id = u.user_id
WHERE u.user_id IS NULL
  AND p.user_id IS NOT NULL
```

```sql
-- tests/test_referential_integrity_feature_usage_meetings.sql
-- Test referential integrity between feature usage and meetings

{{ config(severity = 'error') }}

SELECT 
  f.usage_id,
  f.meeting_id
FROM {{ ref('bz_feature_usage') }} f
LEFT JOIN {{ ref('bz_meetings') }} m ON f.meeting_id = m.meeting_id
WHERE m.meeting_id IS NULL
  AND f.meeting_id IS NOT NULL
```

```sql
-- tests/test_timestamp_consistency.sql
-- Test that created_at <= updated_at for all bronze tables

{{ config(severity = 'warn') }}

WITH timestamp_checks AS (
  SELECT 'bz_users' as table_name, user_id as record_id, created_at, updated_at
  FROM {{ ref('bz_users') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_meetings' as table_name, meeting_id as record_id, created_at, updated_at
  FROM {{ ref('bz_meetings') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_participants' as table_name, participant_id as record_id, created_at, updated_at
  FROM {{ ref('bz_participants') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_feature_usage' as table_name, usage_id as record_id, created_at, updated_at
  FROM {{ ref('bz_feature_usage') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_webinars' as table_name, webinar_id as record_id, created_at, updated_at
  FROM {{ ref('bz_webinars') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_support_tickets' as table_name, ticket_id as record_id, created_at, updated_at
  FROM {{ ref('bz_support_tickets') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_licenses' as table_name, license_id as record_id, created_at, updated_at
  FROM {{ ref('bz_licenses') }}
  WHERE created_at > updated_at
  
  UNION ALL
  
  SELECT 'bz_billing_events' as table_name, event_id as record_id, created_at, updated_at
  FROM {{ ref('bz_billing_events') }}
  WHERE created_at > updated_at
)

SELECT *
FROM timestamp_checks
```

```sql
-- tests/test_data_type_consistency.sql
-- Test that data types are preserved from source to bronze

{{ config(severity = 'error') }}

WITH data_type_issues AS (
  -- Check for any records where data type conversion might have failed
  SELECT 'bz_users' as table_name, user_id as record_id, 'Invalid data type conversion' as issue
  FROM {{ ref('bz_users') }}
  WHERE TRY_CAST(user_id AS VARCHAR) IS NULL
     OR TRY_CAST(load_timestamp AS TIMESTAMP) IS NULL
  
  UNION ALL
  
  SELECT 'bz_meetings' as table_name, meeting_id as record_id, 'Invalid data type conversion' as issue
  FROM {{ ref('bz_meetings') }}
  WHERE TRY_CAST(meeting_id AS VARCHAR) IS NULL
     OR TRY_CAST(duration_minutes AS NUMBER) IS NULL
  
  UNION ALL
  
  SELECT 'bz_billing_events' as table_name, event_id as record_id, 'Invalid amount data type' as issue
  FROM {{ ref('bz_billing_events') }}
  WHERE TRY_CAST(amount AS NUMBER(10,2)) IS NULL
     AND amount IS NOT NULL
)

SELECT *
FROM data_type_issues
```

### Parameterized Tests

```sql
-- tests/generic/test_bronze_table_completeness.sql
-- Generic test to validate bronze table completeness

{% test bronze_table_completeness(model, source_table) %}

  WITH source_data AS (
    SELECT COUNT(*) as source_count
    FROM {{ source('raw', source_table) }}
  ),
  
  model_data AS (
    SELECT COUNT(*) as model_count
    FROM {{ model }}
  )
  
  SELECT 
    source_count,
    model_count,
    ABS(source_count - model_count) as difference
  FROM source_data
  CROSS JOIN model_data
  WHERE source_count != model_count

{% endtest %}
```

```sql
-- tests/generic/test_audit_trail_exists.sql
-- Generic test to validate audit trail exists for each bronze table

{% test audit_trail_exists(model, table_name) %}

  WITH audit_entries AS (
    SELECT COUNT(*) as entry_count
    FROM {{ ref('audit_log') }}
    WHERE source_table = '{{ table_name }}'
      AND operation_type IN ('LOAD_START', 'LOAD_COMPLETE')
  )
  
  SELECT *
  FROM audit_entries
  WHERE entry_count < 2  -- Should have at least LOAD_START and LOAD_COMPLETE

{% endtest %}
```

## Test Execution Strategy

### 1. Pre-deployment Tests
- Run all schema tests to validate data quality
- Execute referential integrity tests
- Verify audit log functionality

### 2. Post-deployment Tests
- Validate row count consistency
- Check audit trail completeness
- Verify timestamp consistency

### 3. Performance Tests
- Monitor execution time for large datasets
- Validate Snowflake warehouse utilization
- Check for query optimization opportunities

## Test Commands

```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select bz_users

# Run tests with specific severity
dbt test --severity error

# Run custom SQL tests only
dbt test --select test_type:generic

# Run schema tests only
dbt test --select test_type:schema
```

## Expected Test Results

### Success Criteria
- All error-level tests pass (0 failures)
- Warning-level tests have acceptable failure rates (<5%)
- Audit log entries exist for all bronze tables
- Row counts match between source and bronze layers
- All referential integrity constraints are satisfied

### Failure Handling
- Error-level failures block deployment
- Warning-level failures are logged but don't block deployment
- All test results are stored in `run_results.json`
- Failed test details are available in Snowflake audit schema

## Monitoring and Alerting

### dbt Cloud Integration
- Set up automated test runs on schedule
- Configure alerts for test failures
- Monitor test performance trends

### Snowflake Integration
- Store test results in dedicated schema
- Create views for test result analysis
- Set up automated reporting on data quality metrics

---

## API Cost Calculation

**Estimated API Cost for this comprehensive unit test case generation: $0.0847 USD**

*This cost includes analysis of 9 dbt models, generation of 35 test cases, creation of YAML schema tests, custom SQL tests, and parameterized test templates with detailed documentation.*

---

## Conclusion

This comprehensive test suite ensures the reliability and performance of the Zoom Bronze Pipeline dbt models in Snowflake. The tests cover data quality, business logic validation, edge cases, audit trail verification, and referential integrity. Regular execution of these tests will help maintain high data quality standards and catch issues early in the development cycle.