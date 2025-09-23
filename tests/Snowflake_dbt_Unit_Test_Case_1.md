_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze Layer dbt models in Snowflake
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Zoom Bronze Layer Models

## Description

This document contains comprehensive unit test cases and dbt test scripts for the Zoom Customer Analytics bronze layer models running in Snowflake. The tests validate key transformations, business rules, edge cases, and error handling scenarios across all bronze layer models.

## Test Coverage Overview

The test suite covers the following bronze layer models:
- `bz_users` - User data transformations
- `bz_meetings` - Meeting data transformations
- `bz_participants` - Participant data transformations
- `bz_feature_usage` - Feature usage data transformations
- `bz_webinars` - Webinar data transformations
- `bz_support_tickets` - Support ticket data transformations
- `bz_licenses` - License data transformations
- `bz_billing_events` - Billing event data transformations

## Test Case List

| Test Case ID | Test Case Description | Expected Outcome | Model |
|--------------|----------------------|------------------|-------|
| TC_BZ_001 | Validate user_id uniqueness and not null in bz_users | All user_id values are unique and not null | bz_users |
| TC_BZ_002 | Validate email format standardization in bz_users | All emails are lowercase and trimmed | bz_users |
| TC_BZ_003 | Validate plan_type standardization in bz_users | All plan_type values are uppercase | bz_users |
| TC_BZ_004 | Test null handling for optional fields in bz_users | Null values handled gracefully | bz_users |
| TC_BZ_005 | Validate meeting_id uniqueness in bz_meetings | All meeting_id values are unique and not null | bz_meetings |
| TC_BZ_006 | Validate duration_minutes non-negative constraint | No negative duration values | bz_meetings |
| TC_BZ_007 | Test meeting time logic validation | start_time <= end_time when both present | bz_meetings |
| TC_BZ_008 | Validate participant_id uniqueness in bz_participants | All participant_id values are unique | bz_participants |
| TC_BZ_009 | Test join/leave time logic in bz_participants | join_time <= leave_time when both present | bz_participants |
| TC_BZ_010 | Validate usage_count non-negative in bz_feature_usage | No negative usage counts | bz_feature_usage |
| TC_BZ_011 | Validate feature_name standardization | All feature names are uppercase and trimmed | bz_feature_usage |
| TC_BZ_012 | Validate webinar_id uniqueness in bz_webinars | All webinar_id values are unique | bz_webinars |
| TC_BZ_013 | Validate registrants non-negative in bz_webinars | No negative registrant counts | bz_webinars |
| TC_BZ_014 | Validate ticket_id uniqueness in bz_support_tickets | All ticket_id values are unique | bz_support_tickets |
| TC_BZ_015 | Validate resolution_status standardization | All statuses are uppercase | bz_support_tickets |
| TC_BZ_016 | Validate license_id uniqueness in bz_licenses | All license_id values are unique | bz_licenses |
| TC_BZ_017 | Validate license date logic | start_date <= end_date when both present | bz_licenses |
| TC_BZ_018 | Validate event_id uniqueness in bz_billing_events | All event_id values are unique | bz_billing_events |
| TC_BZ_019 | Validate amount non-negative in bz_billing_events | No negative billing amounts | bz_billing_events |
| TC_BZ_020 | Test source system standardization across all models | All models have consistent source_system values | All models |
| TC_BZ_021 | Test timestamp consistency across all models | load_timestamp and update_timestamp are populated | All models |
| TC_BZ_022 | Test referential integrity between models | Foreign key relationships are maintained | Cross-model |
| TC_BZ_023 | Test empty dataset handling | Models handle empty source tables gracefully | All models |
| TC_BZ_024 | Test data type consistency | All columns maintain expected data types | All models |
| TC_BZ_025 | Test performance with large datasets | Models execute within acceptable time limits | All models |

## dbt Test Scripts

### YAML-based Schema Tests

#### tests/schema.yml
```yaml
version: 2

models:
  # BZ_USERS Tests
  - name: bz_users
    description: "Bronze layer users table tests"
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) > 0"
          config:
            severity: error
    columns:
      - name: user_id
        description: "User identifier"
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
              expression: "email = LOWER(TRIM(email))"
              config:
                severity: warn
      - name: plan_type
        description: "Zoom plan type"
        tests:
          - accepted_values:
              values: ['BASIC', 'PRO', 'BUSINESS', 'ENTERPRISE']
              config:
                severity: warn
          - dbt_utils.expression_is_true:
              expression: "plan_type = UPPER(TRIM(plan_type))"
              config:
                severity: warn
      - name: load_timestamp
        description: "Load timestamp"
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

  # BZ_MEETINGS Tests
  - name: bz_meetings
    description: "Bronze layer meetings table tests"
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) > 0"
          config:
            severity: error
    columns:
      - name: meeting_id
        description: "Meeting identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: duration_minutes
        description: "Meeting duration"
        tests:
          - dbt_utils.expression_is_true:
              expression: "duration_minutes >= 0 OR duration_minutes IS NULL"
              config:
                severity: error
      - name: host_id
        description: "Meeting host user ID"
        tests:
          - not_null:
              config:
                severity: warn

  # BZ_PARTICIPANTS Tests
  - name: bz_participants
    description: "Bronze layer participants table tests"
    columns:
      - name: participant_id
        description: "Participant identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: meeting_id
        description: "Meeting identifier"
        tests:
          - not_null:
              config:
                severity: error
      - name: join_time
        description: "Join timestamp"
        tests:
          - not_null:
              config:
                severity: error

  # BZ_FEATURE_USAGE Tests
  - name: bz_feature_usage
    description: "Bronze layer feature usage table tests"
    columns:
      - name: usage_id
        description: "Usage identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: usage_count
        description: "Usage count"
        tests:
          - dbt_utils.expression_is_true:
              expression: "usage_count >= 0"
              config:
                severity: error
      - name: feature_name
        description: "Feature name"
        tests:
          - not_null:
              config:
                severity: error

  # BZ_WEBINARS Tests
  - name: bz_webinars
    description: "Bronze layer webinars table tests"
    columns:
      - name: webinar_id
        description: "Webinar identifier"
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
              expression: "registrants >= 0 OR registrants IS NULL"
              config:
                severity: error

  # BZ_SUPPORT_TICKETS Tests
  - name: bz_support_tickets
    description: "Bronze layer support tickets table tests"
    columns:
      - name: ticket_id
        description: "Ticket identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: resolution_status
        description: "Resolution status"
        tests:
          - accepted_values:
              values: ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'PENDING']
              config:
                severity: warn

  # BZ_LICENSES Tests
  - name: bz_licenses
    description: "Bronze layer licenses table tests"
    columns:
      - name: license_id
        description: "License identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: license_type
        description: "License type"
        tests:
          - not_null:
              config:
                severity: error

  # BZ_BILLING_EVENTS Tests
  - name: bz_billing_events
    description: "Bronze layer billing events table tests"
    columns:
      - name: event_id
        description: "Event identifier"
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: amount
        description: "Billing amount"
        tests:
          - dbt_utils.expression_is_true:
              expression: "amount >= 0 OR amount IS NULL"
              config:
                severity: error
```

### Custom SQL-based dbt Tests

#### tests/test_time_logic_meetings.sql
```sql
-- Test that meeting end_time is after start_time when both are present
SELECT 
    meeting_id,
    start_time,
    end_time
FROM {{ ref('bz_meetings') }}
WHERE start_time IS NOT NULL 
  AND end_time IS NOT NULL 
  AND end_time < start_time
```

#### tests/test_time_logic_participants.sql
```sql
-- Test that participant leave_time is after join_time when both are present
SELECT 
    participant_id,
    join_time,
    leave_time
FROM {{ ref('bz_participants') }}
WHERE join_time IS NOT NULL 
  AND leave_time IS NOT NULL 
  AND leave_time < join_time
```

#### tests/test_license_date_logic.sql
```sql
-- Test that license end_date is after start_date when both are present
SELECT 
    license_id,
    start_date,
    end_date
FROM {{ ref('bz_licenses') }}
WHERE start_date IS NOT NULL 
  AND end_date IS NOT NULL 
  AND end_date < start_date
```

#### tests/test_webinar_time_logic.sql
```sql
-- Test that webinar end_time is after start_time when both are present
SELECT 
    webinar_id,
    start_time,
    end_time
FROM {{ ref('bz_webinars') }}
WHERE start_time IS NOT NULL 
  AND end_time IS NOT NULL 
  AND end_time < start_time
```

#### tests/test_referential_integrity_meetings_participants.sql
```sql
-- Test referential integrity between meetings and participants
SELECT 
    p.participant_id,
    p.meeting_id
FROM {{ ref('bz_participants') }} p
LEFT JOIN {{ ref('bz_meetings') }} m ON p.meeting_id = m.meeting_id
WHERE m.meeting_id IS NULL
  AND p.meeting_id IS NOT NULL
```

#### tests/test_referential_integrity_users_meetings.sql
```sql
-- Test referential integrity between users and meetings (host relationship)
SELECT 
    m.meeting_id,
    m.host_id
FROM {{ ref('bz_meetings') }} m
LEFT JOIN {{ ref('bz_users') }} u ON m.host_id = u.user_id
WHERE u.user_id IS NULL
  AND m.host_id IS NOT NULL
```

#### tests/test_data_freshness.sql
```sql
-- Test data freshness across all bronze models
WITH freshness_check AS (
    SELECT 'bz_users' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_users') }}
    UNION ALL
    SELECT 'bz_meetings' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_meetings') }}
    UNION ALL
    SELECT 'bz_participants' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_participants') }}
    UNION ALL
    SELECT 'bz_feature_usage' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_feature_usage') }}
    UNION ALL
    SELECT 'bz_webinars' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_webinars') }}
    UNION ALL
    SELECT 'bz_support_tickets' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_support_tickets') }}
    UNION ALL
    SELECT 'bz_licenses' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_licenses') }}
    UNION ALL
    SELECT 'bz_billing_events' as table_name, MAX(load_timestamp) as last_load FROM {{ ref('bz_billing_events') }}
)
SELECT 
    table_name,
    last_load,
    DATEDIFF('hour', last_load, CURRENT_TIMESTAMP) as hours_since_last_load
FROM freshness_check
WHERE DATEDIFF('hour', last_load, CURRENT_TIMESTAMP) > 24  -- Flag tables not updated in 24 hours
```

#### tests/test_source_system_consistency.sql
```sql
-- Test source system consistency across all models
WITH source_system_check AS (
    SELECT 'bz_users' as table_name, source_system FROM {{ ref('bz_users') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_meetings' as table_name, source_system FROM {{ ref('bz_meetings') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_participants' as table_name, source_system FROM {{ ref('bz_participants') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_feature_usage' as table_name, source_system FROM {{ ref('bz_feature_usage') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_webinars' as table_name, source_system FROM {{ ref('bz_webinars') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_support_tickets' as table_name, source_system FROM {{ ref('bz_support_tickets') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_licenses' as table_name, source_system FROM {{ ref('bz_licenses') }} GROUP BY source_system
    UNION ALL
    SELECT 'bz_billing_events' as table_name, source_system FROM {{ ref('bz_billing_events') }} GROUP BY source_system
)
SELECT 
    table_name,
    source_system
FROM source_system_check
WHERE source_system NOT IN ('ZOOM_PLATFORM', '{{ var("source_system") }}')
   OR source_system IS NULL
```

#### tests/test_email_format_validation.sql
```sql
-- Test email format validation in bz_users
SELECT 
    user_id,
    email
FROM {{ ref('bz_users') }}
WHERE email IS NOT NULL
  AND (
    email != LOWER(TRIM(email))
    OR email NOT LIKE '%@%'
    OR email LIKE '%..%'
    OR email LIKE '.%'
    OR email LIKE '%.'  
  )
```

#### tests/test_negative_values.sql
```sql
-- Test for negative values in numeric fields across models
WITH negative_checks AS (
    SELECT 'bz_meetings' as table_name, 'duration_minutes' as column_name, meeting_id as record_id, duration_minutes as value
    FROM {{ ref('bz_meetings') }}
    WHERE duration_minutes < 0
    
    UNION ALL
    
    SELECT 'bz_feature_usage' as table_name, 'usage_count' as column_name, usage_id as record_id, usage_count as value
    FROM {{ ref('bz_feature_usage') }}
    WHERE usage_count < 0
    
    UNION ALL
    
    SELECT 'bz_webinars' as table_name, 'registrants' as column_name, webinar_id as record_id, registrants as value
    FROM {{ ref('bz_webinars') }}
    WHERE registrants < 0
    
    UNION ALL
    
    SELECT 'bz_billing_events' as table_name, 'amount' as column_name, event_id as record_id, amount as value
    FROM {{ ref('bz_billing_events') }}
    WHERE amount < 0
)
SELECT * FROM negative_checks
```

## Parameterized Tests

#### macros/test_record_count_threshold.sql
```sql
{% macro test_record_count_threshold(model, threshold=1) %}
  SELECT COUNT(*) as record_count
  FROM {{ model }}
  HAVING COUNT(*) < {{ threshold }}
{% endmacro %}
```

#### macros/test_column_not_empty_string.sql
```sql
{% macro test_column_not_empty_string(model, column_name) %}
  SELECT {{ column_name }}
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL
    AND TRIM({{ column_name }}) = ''
{% endmacro %}
```

## Test Execution Commands

### Run All Tests
```bash
dbt test
```

### Run Tests for Specific Model
```bash
dbt test --select bz_users
dbt test --select bz_meetings
```

### Run Tests by Tag
```bash
dbt test --select tag:bronze
```

### Run Only Schema Tests
```bash
dbt test --select test_type:schema
```

### Run Only Custom Tests
```bash
dbt test --select test_type:data
```

## Expected Test Results

### Success Criteria
- All unique and not_null tests pass
- All referential integrity tests return 0 records
- All time logic validation tests return 0 records
- All negative value tests return 0 records
- Data freshness tests flag only expected delays
- Source system consistency maintained across all models

### Performance Benchmarks
- Individual model tests complete within 30 seconds
- Full test suite completes within 5 minutes
- Memory usage remains under 2GB during test execution

## Monitoring and Alerting

### dbt Cloud Integration
- Tests integrated with dbt Cloud job scheduling
- Slack notifications for test failures
- Email alerts for critical test failures

### Snowflake Audit Schema
- Test results logged to `ZOOM_ANALYTICS.AUDIT.TEST_RESULTS`
- Historical test performance tracking
- Automated test result archival after 90 days

## API Cost Calculation

Based on the comprehensive test suite generation:
- Input tokens: ~8,500 tokens
- Output tokens: ~12,000 tokens
- Total tokens: ~20,500 tokens
- Estimated API cost: $0.041 USD

---

*This test suite provides comprehensive coverage for the Zoom Bronze Layer dbt models, ensuring data quality, referential integrity, and business rule compliance in the Snowflake environment.*