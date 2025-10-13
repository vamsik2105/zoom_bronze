_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze layer dbt models in Snowflake
## *Version*: 1 
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases - Zoom Bronze Pipeline

## Overview

This document contains comprehensive unit test cases and dbt test scripts for the Zoom Bronze layer transformation pipeline. The tests validate data transformations, business rules, edge cases, and error handling across all bronze layer models.

## Test Case List

### 1. BZ_AUDIT_LOG Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_AUDIT_001 | Verify audit log table structure and initialization | Table created with correct schema, no initial data |
| TC_AUDIT_002 | Test record_id data type and constraints | record_id should be NUMBER type |
| TC_AUDIT_003 | Validate source_table VARCHAR(50) constraint | Field accepts up to 50 characters |
| TC_AUDIT_004 | Test timestamp fields for proper data types | load_timestamp should be TIMESTAMP_NTZ |

### 2. BZ_USERS Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_USERS_001 | Verify user_id uniqueness | No duplicate user_id values |
| TC_USERS_002 | Test NULL handling with COALESCE | NULL values replaced with 'UNKNOWN' |
| TC_USERS_003 | Validate email format and not null | All emails should be valid or 'UNKNOWN' |
| TC_USERS_004 | Test plan_type accepted values | Only valid plan types or 'UNKNOWN' |
| TC_USERS_005 | Verify update_timestamp generation | All records have current timestamp |
| TC_USERS_006 | Test source system default assignment | Missing source_system becomes 'ZOOM_PLATFORM' |
| TC_USERS_007 | Validate load_timestamp handling | NULL load_timestamp gets CURRENT_TIMESTAMP() |

### 3. BZ_MEETINGS Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_MEETINGS_001 | Verify meeting_id uniqueness | No duplicate meeting_id values |
| TC_MEETINGS_002 | Test host_id relationship with users | Valid host_id references existing users |
| TC_MEETINGS_003 | Validate duration_minutes calculation | Duration should be >= 0 |
| TC_MEETINGS_004 | Test start_time and end_time logic | end_time should be >= start_time |
| TC_MEETINGS_005 | Verify NULL handling for duration | NULL duration becomes 0 |
| TC_MEETINGS_006 | Test meeting_topic length constraints | Topic field handles various lengths |
| TC_MEETINGS_007 | Validate timestamp data types | Proper timestamp handling |

### 4. BZ_PARTICIPANTS Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_PARTICIPANTS_001 | Verify participant_id uniqueness | No duplicate participant_id values |
| TC_PARTICIPANTS_002 | Test meeting_id foreign key relationship | Valid meeting_id references existing meetings |
| TC_PARTICIPANTS_003 | Validate user_id foreign key relationship | Valid user_id references existing users |
| TC_PARTICIPANTS_004 | Test join_time and leave_time logic | leave_time should be >= join_time |
| TC_PARTICIPANTS_005 | Verify NULL handling for timestamps | Proper NULL timestamp handling |
| TC_PARTICIPANTS_006 | Test participant session duration | Calculate valid session durations |

### 5. BZ_FEATURE_USAGE Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_FEATURE_001 | Verify usage_id uniqueness | No duplicate usage_id values |
| TC_FEATURE_002 | Test meeting_id relationship | Valid meeting_id references |
| TC_FEATURE_003 | Validate usage_count constraints | usage_count should be >= 0 |
| TC_FEATURE_004 | Test feature_name accepted values | Valid feature names or 'UNKNOWN' |
| TC_FEATURE_005 | Verify usage_date format | Proper date format validation |
| TC_FEATURE_006 | Test NULL handling for usage_count | NULL usage_count becomes 0 |

### 6. BZ_WEBINARS Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_WEBINARS_001 | Verify webinar_id uniqueness | No duplicate webinar_id values |
| TC_WEBINARS_002 | Test host_id relationship | Valid host_id references |
| TC_WEBINARS_003 | Validate registrants count | registrants should be >= 0 |
| TC_WEBINARS_004 | Test webinar duration logic | end_time >= start_time |
| TC_WEBINARS_005 | Verify NULL handling for registrants | NULL registrants becomes 0 |
| TC_WEBINARS_006 | Test webinar_topic constraints | Topic field validation |

### 7. BZ_SUPPORT_TICKETS Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_TICKETS_001 | Verify ticket_id uniqueness | No duplicate ticket_id values |
| TC_TICKETS_002 | Test user_id relationship | Valid user_id references |
| TC_TICKETS_003 | Validate ticket_type accepted values | Valid ticket types |
| TC_TICKETS_004 | Test resolution_status values | Valid status values |
| TC_TICKETS_005 | Verify open_date format | Proper date validation |
| TC_TICKETS_006 | Test NULL handling across fields | Proper NULL replacement |

### 8. BZ_LICENSES Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_LICENSES_001 | Verify license_id uniqueness | No duplicate license_id values |
| TC_LICENSES_002 | Test assigned_to_user_id relationship | Valid user references |
| TC_LICENSES_003 | Validate license date logic | end_date >= start_date |
| TC_LICENSES_004 | Test license_type accepted values | Valid license types |
| TC_LICENSES_005 | Verify active license calculation | Proper date range validation |
| TC_LICENSES_006 | Test NULL handling for dates | Proper NULL date handling |

### 9. BZ_BILLING_EVENTS Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| TC_BILLING_001 | Verify event_id uniqueness | No duplicate event_id values |
| TC_BILLING_002 | Test user_id relationship | Valid user references |
| TC_BILLING_003 | Validate amount constraints | amount should be >= 0 |
| TC_BILLING_004 | Test event_type accepted values | Valid event types |
| TC_BILLING_005 | Verify event_date format | Proper date validation |
| TC_BILLING_006 | Test NULL handling for amount | NULL amount becomes 0 |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# tests/schema.yml
version: 2

models:
  - name: bz_users
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - user_id
            - email
    columns:
      - name: user_id
        tests:
          - not_null
          - unique
      - name: email
        tests:
          - not_null
          - dbt_utils.not_empty_string
      - name: plan_type
        tests:
          - accepted_values:
              values: ['BASIC', 'PRO', 'BUSINESS', 'ENTERPRISE', 'UNKNOWN']
      - name: update_timestamp
        tests:
          - not_null
      - name: source_system
        tests:
          - not_null
          - accepted_values:
              values: ['ZOOM_PLATFORM', 'UNKNOWN']

  - name: bz_meetings
    tests:
      - dbt_utils.expression_is_true:
          expression: "end_time >= start_time OR end_time IS NULL"
    columns:
      - name: meeting_id
        tests:
          - not_null
          - unique
      - name: host_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_users')
              field: user_id
      - name: duration_minutes
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: update_timestamp
        tests:
          - not_null

  - name: bz_participants
    tests:
      - dbt_utils.expression_is_true:
          expression: "leave_time >= join_time OR leave_time IS NULL"
    columns:
      - name: participant_id
        tests:
          - not_null
          - unique
      - name: meeting_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_meetings')
              field: meeting_id
      - name: user_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_users')
              field: user_id

  - name: bz_feature_usage
    columns:
      - name: usage_id
        tests:
          - not_null
          - unique
      - name: meeting_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_meetings')
              field: meeting_id
      - name: usage_count
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: feature_name
        tests:
          - not_null
          - accepted_values:
              values: ['SCREEN_SHARE', 'CHAT', 'RECORDING', 'BREAKOUT_ROOMS', 'WHITEBOARD', 'UNKNOWN']

  - name: bz_webinars
    tests:
      - dbt_utils.expression_is_true:
          expression: "end_time >= start_time OR end_time IS NULL"
    columns:
      - name: webinar_id
        tests:
          - not_null
          - unique
      - name: host_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_users')
              field: user_id
      - name: registrants
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"

  - name: bz_support_tickets
    columns:
      - name: ticket_id
        tests:
          - not_null
          - unique
      - name: user_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_users')
              field: user_id
      - name: ticket_type
        tests:
          - not_null
          - accepted_values:
              values: ['TECHNICAL', 'BILLING', 'ACCOUNT', 'FEATURE_REQUEST', 'UNKNOWN']
      - name: resolution_status
        tests:
          - not_null
          - accepted_values:
              values: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'UNKNOWN']

  - name: bz_licenses
    tests:
      - dbt_utils.expression_is_true:
          expression: "end_date >= start_date OR end_date IS NULL"
    columns:
      - name: license_id
        tests:
          - not_null
          - unique
      - name: assigned_to_user_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_users')
              field: user_id
      - name: license_type
        tests:
          - not_null
          - accepted_values:
              values: ['BASIC', 'PRO', 'BUSINESS', 'ENTERPRISE', 'UNKNOWN']

  - name: bz_billing_events
    columns:
      - name: event_id
        tests:
          - not_null
          - unique
      - name: user_id
        tests:
          - not_null
          - relationships:
              to: ref('bz_users')
              field: user_id
      - name: amount
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: event_type
        tests:
          - not_null
          - accepted_values:
              values: ['CHARGE', 'REFUND', 'CREDIT', 'ADJUSTMENT', 'UNKNOWN']

  - name: bz_audit_log
    columns:
      - name: record_id
        tests:
          - not_null
      - name: source_table
        tests:
          - not_null
      - name: load_timestamp
        tests:
          - not_null
      - name: status
        tests:
          - not_null
          - accepted_values:
              values: ['INITIALIZED', 'STARTED', 'COMPLETED', 'FAILED']
```

### Custom SQL-based dbt Tests

```sql
-- tests/test_users_email_format.sql
-- Test to validate email format in bz_users
SELECT user_id, email
FROM {{ ref('bz_users') }}
WHERE email != 'UNKNOWN' 
  AND email NOT RLIKE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
```

```sql
-- tests/test_meeting_duration_consistency.sql
-- Test to validate meeting duration calculation
SELECT meeting_id, start_time, end_time, duration_minutes
FROM {{ ref('bz_meetings') }}
WHERE start_time IS NOT NULL 
  AND end_time IS NOT NULL
  AND ABS(DATEDIFF('minute', start_time, end_time) - duration_minutes) > 1
```

```sql
-- tests/test_participant_session_logic.sql
-- Test to validate participant session timing
SELECT p.participant_id, p.join_time, p.leave_time, m.start_time, m.end_time
FROM {{ ref('bz_participants') }} p
JOIN {{ ref('bz_meetings') }} m ON p.meeting_id = m.meeting_id
WHERE p.join_time IS NOT NULL 
  AND m.start_time IS NOT NULL
  AND p.join_time < m.start_time
```

```sql
-- tests/test_license_overlap.sql
-- Test to identify overlapping licenses for same user
SELECT assigned_to_user_id, COUNT(*) as overlapping_licenses
FROM {{ ref('bz_licenses') }}
WHERE start_date IS NOT NULL 
  AND end_date IS NOT NULL
  AND assigned_to_user_id != 'UNKNOWN'
GROUP BY assigned_to_user_id, start_date, end_date
HAVING COUNT(*) > 1
```

```sql
-- tests/test_billing_amount_validation.sql
-- Test to validate billing amounts are reasonable
SELECT event_id, amount, event_type
FROM {{ ref('bz_billing_events') }}
WHERE amount < 0 OR amount > 10000
```

```sql
-- tests/test_feature_usage_consistency.sql
-- Test to validate feature usage against meetings
SELECT fu.usage_id, fu.meeting_id, fu.usage_date, m.start_time
FROM {{ ref('bz_feature_usage') }} fu
JOIN {{ ref('bz_meetings') }} m ON fu.meeting_id = m.meeting_id
WHERE fu.usage_date IS NOT NULL 
  AND m.start_time IS NOT NULL
  AND DATE(fu.usage_date) != DATE(m.start_time)
```

```sql
-- tests/test_webinar_registrant_logic.sql
-- Test to validate webinar registrant counts
SELECT webinar_id, registrants, start_time, end_time
FROM {{ ref('bz_webinars') }}
WHERE registrants > 10000 -- Assuming max capacity
   OR registrants < 0
```

```sql
-- tests/test_support_ticket_timeline.sql
-- Test to validate support ticket open dates
SELECT ticket_id, open_date, user_id
FROM {{ ref('bz_support_tickets') }}
WHERE open_date > CURRENT_DATE()
   OR open_date < '2020-01-01' -- Assuming business start date
```

### Parameterized Tests

```sql
-- macros/test_null_replacement.sql
{% macro test_null_replacement(model, column_name, expected_value) %}
  SELECT {{ column_name }}
  FROM {{ model }}
  WHERE {{ column_name }} IS NULL
     OR {{ column_name }} != '{{ expected_value }}'
{% endmacro %}
```

```sql
-- tests/test_users_null_handling.sql
{{ test_null_replacement(ref('bz_users'), 'user_name', 'UNKNOWN') }}
```

```sql
-- macros/test_timestamp_generation.sql
{% macro test_timestamp_generation(model) %}
  SELECT *
  FROM {{ model }}
  WHERE update_timestamp IS NULL
     OR update_timestamp > CURRENT_TIMESTAMP()
     OR update_timestamp < load_timestamp
{% endmacro %}
```

### Edge Case Tests

```sql
-- tests/test_empty_source_tables.sql
-- Test behavior when source tables are empty
WITH source_counts AS (
  SELECT 'users' as table_name, COUNT(*) as row_count FROM {{ source('raw_data', 'users') }}
  UNION ALL
  SELECT 'meetings' as table_name, COUNT(*) as row_count FROM {{ source('raw_data', 'meetings') }}
  UNION ALL
  SELECT 'participants' as table_name, COUNT(*) as row_count FROM {{ source('raw_data', 'participants') }}
)
SELECT table_name, row_count
FROM source_counts
WHERE row_count = 0
```

```sql
-- tests/test_data_type_consistency.sql
-- Test to ensure data type consistency across transformations
SELECT 
  'bz_users' as model_name,
  COUNT(CASE WHEN TRY_CAST(user_id AS VARCHAR) IS NULL THEN 1 END) as invalid_user_ids
FROM {{ ref('bz_users') }}
UNION ALL
SELECT 
  'bz_meetings' as model_name,
  COUNT(CASE WHEN TRY_CAST(duration_minutes AS NUMBER) IS NULL THEN 1 END) as invalid_durations
FROM {{ ref('bz_meetings') }}
```

## Test Execution Strategy

### 1. Pre-deployment Tests
- Run all schema tests using `dbt test`
- Execute custom SQL tests
- Validate data quality metrics

### 2. Post-deployment Validation
- Monitor test results in `run_results.json`
- Check Snowflake audit schema for test execution logs
- Validate row counts and data consistency

### 3. Continuous Monitoring
- Schedule regular test execution
- Set up alerts for test failures
- Monitor performance metrics

## Performance Considerations

1. **Test Optimization**: Use sampling for large datasets
2. **Parallel Execution**: Leverage dbt's parallel test execution
3. **Resource Management**: Configure appropriate warehouse sizes
4. **Test Scheduling**: Run tests during off-peak hours

## Error Handling and Alerting

1. **Test Failure Notifications**: Configure alerts for critical test failures
2. **Data Quality Thresholds**: Set acceptable error rates
3. **Escalation Procedures**: Define response procedures for different failure types
4. **Recovery Processes**: Document data recovery and reprocessing steps

---

**API Cost Calculation**: $0.0245 USD

*This comprehensive test suite ensures the reliability and performance of the Zoom Bronze layer dbt models in Snowflake by validating data transformations, business rules, edge cases, and error handling scenarios.*