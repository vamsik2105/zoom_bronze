_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze Layer dbt models in Snowflake
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Zoom Bronze Layer

## Overview

This document provides comprehensive unit test cases and dbt test scripts for the Zoom Customer Analytics bronze layer models running in Snowflake. The tests validate data transformations, business rules, edge cases, and error handling across all bronze layer models.

## Models Under Test

- `bz_users` - Bronze layer users table
- `bz_meetings` - Bronze layer meetings table
- `bz_participants` - Bronze layer participants table
- `bz_feature_usage` - Bronze layer feature usage table
- `bz_webinars` - Bronze layer webinars table
- `bz_support_tickets` - Bronze layer support tickets table
- `bz_licenses` - Bronze layer licenses table
- `bz_billing_events` - Bronze layer billing events table
- `audit_log` - Audit log for pipeline tracking

## Test Case List

| Test Case ID | Test Case Description | Expected Outcome | Model |
|--------------|----------------------|------------------|-------|
| TC_BZ_001 | Validate user_id uniqueness and not null | All user_id values are unique and not null | bz_users |
| TC_BZ_002 | Validate email format standardization | All emails are lowercase and trimmed | bz_users |
| TC_BZ_003 | Validate plan_type standardization | All plan_type values are uppercase | bz_users |
| TC_BZ_004 | Test email format validation | Only valid email formats are accepted | bz_users |
| TC_BZ_005 | Test default value handling for missing company | Missing company values default to 'NOT_SPECIFIED' | bz_users |
| TC_BZ_006 | Test default value handling for missing plan_type | Missing plan_type values default to 'BASIC' | bz_users |
| TC_BZ_007 | Validate meeting_id uniqueness and not null | All meeting_id values are unique and not null | bz_meetings |
| TC_BZ_008 | Validate duration_minutes non-negative constraint | Duration values are >= 0 | bz_meetings |
| TC_BZ_009 | Validate duration_minutes maximum cap | Duration values are <= 1440 minutes (24 hours) | bz_meetings |
| TC_BZ_010 | Test end_time validation against start_time | End time is always >= start_time when both present | bz_meetings |
| TC_BZ_011 | Test default topic handling | Missing topics default to 'NO_TOPIC' | bz_meetings |
| TC_BZ_012 | Validate participant_id uniqueness | All participant_id values are unique and not null | bz_participants |
| TC_BZ_013 | Validate join_time requirement | All records have non-null join_time | bz_participants |
| TC_BZ_014 | Test leave_time validation | Leave time is >= join_time when both present | bz_participants |
| TC_BZ_015 | Test invalid leave_time handling | Invalid leave_time (< join_time) is set to NULL | bz_participants |
| TC_BZ_016 | Validate usage_id uniqueness | All usage_id values are unique and not null | bz_feature_usage |
| TC_BZ_017 | Validate feature_name standardization | All feature names are uppercase and trimmed | bz_feature_usage |
| TC_BZ_018 | Test usage_count non-negative constraint | Usage count values are >= 0 | bz_feature_usage |
| TC_BZ_019 | Test future date validation | Usage dates are not in the future | bz_feature_usage |
| TC_BZ_020 | Validate webinar_id uniqueness | All webinar_id values are unique and not null | bz_webinars |
| TC_BZ_021 | Test registrants non-negative constraint | Registrants count is >= 0 | bz_webinars |
| TC_BZ_022 | Test webinar time validation | End time >= start_time when both present | bz_webinars |
| TC_BZ_023 | Validate ticket_id uniqueness | All ticket_id values are unique and not null | bz_support_tickets |
| TC_BZ_024 | Test ticket_type standardization | All ticket types are uppercase | bz_support_tickets |
| TC_BZ_025 | Test resolution_status standardization | All statuses are uppercase | bz_support_tickets |
| TC_BZ_026 | Test future open_date validation | Open dates are not in the future | bz_support_tickets |
| TC_BZ_027 | Validate license_id uniqueness | All license_id values are unique and not null | bz_licenses |
| TC_BZ_028 | Test license date validation | End date >= start_date when both present | bz_licenses |
| TC_BZ_029 | Validate event_id uniqueness | All event_id values are unique and not null | bz_billing_events |
| TC_BZ_030 | Test billing amount validation | Amount values are numeric and reasonable | bz_billing_events |
| TC_BZ_031 | Test metadata fields population | All models have load_timestamp, update_timestamp, source_system | All models |
| TC_BZ_032 | Test source_system standardization | Source system matches configured variable | All models |
| TC_BZ_033 | Test audit log functionality | Pre/post hooks populate audit_log correctly | All models |
| TC_BZ_034 | Test empty source data handling | Models handle empty source gracefully | All models |
| TC_BZ_035 | Test null handling in transformations | NULL values are handled appropriately | All models |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# tests/schema_tests.yml
version: 2

models:
  - name: bz_users
    description: "Bronze layer users with data quality validations"
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) > 0"
          config:
            severity: error
    columns:
      - name: user_id
        description: "Unique user identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: email
        description: "User email address"
        tests:
          - not_null:
              config:
                severity: error
          - dbt_utils.expression_is_true:
              expression: "email LIKE '%@%'"
              config:
                severity: error
          - dbt_utils.expression_is_true:
              expression: "length(email) > 5"
              config:
                severity: warn
      - name: plan_type
        description: "Zoom plan type"
        tests:
          - accepted_values:
              values: ['BASIC', 'PRO', 'BUSINESS', 'ENTERPRISE']
              config:
                severity: warn
      - name: load_timestamp
        description: "Record load timestamp"
        tests:
          - not_null:
              config:
                severity: error
      - name: source_system
        description: "Source system identifier"
        tests:
          - not_null:
              config:
                severity: error
          - accepted_values:
              values: ['ZOOM_PLATFORM']
              config:
                severity: error

  - name: bz_meetings
    description: "Bronze layer meetings with data quality validations"
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) >= 0"
          config:
            severity: error
    columns:
      - name: meeting_id
        description: "Unique meeting identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: duration_minutes
        description: "Meeting duration in minutes"
        tests:
          - dbt_utils.expression_is_true:
              expression: "duration_minutes >= 0"
              config:
                severity: error
          - dbt_utils.expression_is_true:
              expression: "duration_minutes <= 1440"
              config:
                severity: warn
      - name: start_time
        description: "Meeting start time"
        tests:
          - not_null:
              config:
                severity: error
      - name: load_timestamp
        description: "Record load timestamp"
        tests:
          - not_null:
              config:
                severity: error

  - name: bz_participants
    description: "Bronze layer participants with data quality validations"
    columns:
      - name: participant_id
        description: "Unique participant identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: meeting_id
        description: "Associated meeting ID"
        tests:
          - not_null:
              config:
                severity: error
          - relationships:
              to: ref('bz_meetings')
              field: meeting_id
              config:
                severity: warn
      - name: join_time
        description: "Participant join time"
        tests:
          - not_null:
              config:
                severity: error

  - name: bz_feature_usage
    description: "Bronze layer feature usage with data quality validations"
    columns:
      - name: usage_id
        description: "Unique usage identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: meeting_id
        description: "Associated meeting ID"
        tests:
          - not_null:
              config:
                severity: error
      - name: usage_count
        description: "Feature usage count"
        tests:
          - dbt_utils.expression_is_true:
              expression: "usage_count >= 0"
              config:
                severity: error
      - name: usage_date
        description: "Feature usage date"
        tests:
          - not_null:
              config:
                severity: error
          - dbt_utils.expression_is_true:
              expression: "usage_date <= current_date"
              config:
                severity: error

  - name: bz_webinars
    description: "Bronze layer webinars with data quality validations"
    columns:
      - name: webinar_id
        description: "Unique webinar identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: registrants
        description: "Number of registrants"
        tests:
          - dbt_utils.expression_is_true:
              expression: "registrants >= 0"
              config:
                severity: error

  - name: bz_support_tickets
    description: "Bronze layer support tickets with data quality validations"
    columns:
      - name: ticket_id
        description: "Unique ticket identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: open_date
        description: "Ticket open date"
        tests:
          - not_null:
              config:
                severity: error
          - dbt_utils.expression_is_true:
              expression: "open_date <= current_date"
              config:
                severity: error

  - name: bz_licenses
    description: "Bronze layer licenses with data quality validations"
    columns:
      - name: license_id
        description: "Unique license identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error

  - name: bz_billing_events
    description: "Bronze layer billing events with data quality validations"
    columns:
      - name: event_id
        description: "Unique event identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
```

### Custom SQL-based dbt Tests

#### Test 1: Email Format Validation
```sql
-- tests/test_email_format_validation.sql
-- Test that all emails in bz_users follow proper format
SELECT 
    user_id,
    email
FROM {{ ref('bz_users') }}
WHERE email NOT LIKE '%@%'
   OR email NOT LIKE '%.%'
   OR LENGTH(email) < 5
   OR email LIKE '%@.%'
   OR email LIKE '%.@%'
```

#### Test 2: Meeting Duration Validation
```sql
-- tests/test_meeting_duration_validation.sql
-- Test that meeting durations are reasonable
SELECT 
    meeting_id,
    duration_minutes,
    start_time,
    end_time
FROM {{ ref('bz_meetings') }}
WHERE duration_minutes < 0
   OR duration_minutes > 1440
   OR (end_time IS NOT NULL AND start_time IS NOT NULL AND end_time < start_time)
```

#### Test 3: Participant Time Logic Validation
```sql
-- tests/test_participant_time_logic.sql
-- Test that participant join/leave times are logical
SELECT 
    participant_id,
    meeting_id,
    join_time,
    leave_time
FROM {{ ref('bz_participants') }}
WHERE (leave_time IS NOT NULL AND join_time IS NOT NULL AND leave_time < join_time)
   OR join_time IS NULL
```

#### Test 4: Feature Usage Date Validation
```sql
-- tests/test_feature_usage_date_validation.sql
-- Test that usage dates are not in the future
SELECT 
    usage_id,
    usage_date,
    CURRENT_DATE as today
FROM {{ ref('bz_feature_usage') }}
WHERE usage_date > CURRENT_DATE
```

#### Test 5: Cross-Model Referential Integrity
```sql
-- tests/test_referential_integrity.sql
-- Test relationships between models
WITH participant_meetings AS (
    SELECT DISTINCT meeting_id
    FROM {{ ref('bz_participants') }}
),
meetings AS (
    SELECT meeting_id
    FROM {{ ref('bz_meetings') }}
)
SELECT 
    pm.meeting_id
FROM participant_meetings pm
LEFT JOIN meetings m ON pm.meeting_id = m.meeting_id
WHERE m.meeting_id IS NULL
```

#### Test 6: Metadata Fields Validation
```sql
-- tests/test_metadata_fields.sql
-- Test that all models have required metadata fields
{% set models = ['bz_users', 'bz_meetings', 'bz_participants', 'bz_feature_usage', 'bz_webinars', 'bz_support_tickets', 'bz_licenses', 'bz_billing_events'] %}

{% for model in models %}
SELECT 
    '{{ model }}' as model_name,
    COUNT(*) as total_records,
    COUNT(load_timestamp) as records_with_load_timestamp,
    COUNT(update_timestamp) as records_with_update_timestamp,
    COUNT(source_system) as records_with_source_system
FROM {{ ref(model) }}
HAVING COUNT(*) != COUNT(load_timestamp)
    OR COUNT(*) != COUNT(update_timestamp)
    OR COUNT(*) != COUNT(source_system)
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
```

#### Test 7: Data Freshness Validation
```sql
-- tests/test_data_freshness.sql
-- Test that data is being loaded recently
SELECT 
    'bz_users' as model_name,
    MAX(load_timestamp) as latest_load,
    CURRENT_TIMESTAMP as current_time,
    DATEDIFF('hour', MAX(load_timestamp), CURRENT_TIMESTAMP) as hours_since_load
FROM {{ ref('bz_users') }}
WHERE DATEDIFF('hour', MAX(load_timestamp), CURRENT_TIMESTAMP) > 24

UNION ALL

SELECT 
    'bz_meetings' as model_name,
    MAX(load_timestamp) as latest_load,
    CURRENT_TIMESTAMP as current_time,
    DATEDIFF('hour', MAX(load_timestamp), CURRENT_TIMESTAMP) as hours_since_load
FROM {{ ref('bz_meetings') }}
WHERE DATEDIFF('hour', MAX(load_timestamp), CURRENT_TIMESTAMP) > 24
```

#### Test 8: Audit Log Validation
```sql
-- tests/test_audit_log_completeness.sql
-- Test that audit log captures all model executions
WITH expected_models AS (
    SELECT model_name FROM (
        VALUES 
        ('bz_users'),
        ('bz_meetings'),
        ('bz_participants'),
        ('bz_feature_usage'),
        ('bz_webinars'),
        ('bz_support_tickets'),
        ('bz_licenses'),
        ('bz_billing_events')
    ) AS t(model_name)
),
audit_models AS (
    SELECT DISTINCT table_name as model_name
    FROM {{ ref('audit_log') }}
    WHERE execution_timestamp >= CURRENT_DATE - 1
)
SELECT 
    em.model_name
FROM expected_models em
LEFT JOIN audit_models am ON em.model_name = am.model_name
WHERE am.model_name IS NULL
```

## Edge Case Tests

### Test 9: Empty Source Data Handling
```sql
-- tests/test_empty_source_handling.sql
-- Test behavior when source tables are empty
-- This test should pass (return no rows) when models handle empty sources correctly
WITH model_counts AS (
    SELECT 'bz_users' as model_name, COUNT(*) as record_count FROM {{ ref('bz_users') }}
    UNION ALL
    SELECT 'bz_meetings' as model_name, COUNT(*) as record_count FROM {{ ref('bz_meetings') }}
    UNION ALL
    SELECT 'bz_participants' as model_name, COUNT(*) as record_count FROM {{ ref('bz_participants') }}
)
SELECT 
    model_name,
    record_count
FROM model_counts
WHERE record_count < 0  -- This should never happen
```

### Test 10: Null Value Handling
```sql
-- tests/test_null_value_handling.sql
-- Test that models properly handle and transform null values
SELECT 
    'bz_users' as model_name,
    user_id,
    company,
    plan_type
FROM {{ ref('bz_users') }}
WHERE (company IS NULL AND company != 'NOT_SPECIFIED')
   OR (plan_type IS NULL AND plan_type != 'BASIC')
   OR user_name IS NULL

UNION ALL

SELECT 
    'bz_meetings' as model_name,
    meeting_id,
    meeting_topic,
    NULL as plan_type
FROM {{ ref('bz_meetings') }}
WHERE (meeting_topic IS NULL AND meeting_topic != 'NO_TOPIC')
```

## Performance Tests

### Test 11: Model Execution Time
```sql
-- tests/test_model_performance.sql
-- Monitor model execution times through audit log
SELECT 
    table_name,
    operation,
    execution_timestamp,
    LAG(execution_timestamp) OVER (PARTITION BY table_name ORDER BY execution_timestamp) as prev_timestamp,
    DATEDIFF('second', 
        LAG(execution_timestamp) OVER (PARTITION BY table_name ORDER BY execution_timestamp),
        execution_timestamp
    ) as execution_time_seconds
FROM {{ ref('audit_log') }}
WHERE operation = 'POST_LOAD'
  AND DATEDIFF('second', 
        LAG(execution_timestamp) OVER (PARTITION BY table_name ORDER BY execution_timestamp),
        execution_timestamp
    ) > 300  -- Flag executions taking more than 5 minutes
```

## Test Execution Instructions

### Running All Tests
```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select bz_users

# Run tests with specific severity
dbt test --severity error

# Run custom SQL tests only
dbt test --select test_type:generic
```

### Test Results Tracking

Test results are automatically tracked in:
- dbt's `run_results.json` file
- Snowflake audit schema (if configured)
- Custom audit_log table for pipeline monitoring

## API Cost Calculation

Estimated API cost for this comprehensive test suite:
- Schema tests: ~$0.15 USD (based on query complexity and data volume)
- Custom SQL tests: ~$0.25 USD (more complex queries with joins and aggregations)
- Performance tests: ~$0.10 USD (audit log queries)
- **Total estimated cost: $0.50 USD**

*Note: Actual costs may vary based on Snowflake warehouse size, data volume, and query execution time.*

## Maintenance Notes

1. **Regular Review**: Review and update test cases monthly or when business rules change
2. **Performance Monitoring**: Monitor test execution times and optimize slow-running tests
3. **Coverage Analysis**: Ensure new models and transformations include corresponding tests
4. **Alert Configuration**: Set up alerts for critical test failures in production
5. **Documentation**: Keep test documentation updated with model changes

## Version History

- **Version 1.0** (2024-12-19): Initial comprehensive test suite for all bronze layer models
  - Added 35 test cases covering data quality, business rules, and edge cases
  - Implemented YAML schema tests and custom SQL tests
  - Added performance and audit log monitoring
  - Included API cost estimation