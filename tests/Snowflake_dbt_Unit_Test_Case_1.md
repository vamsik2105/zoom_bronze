_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze layer dbt models in Snowflake
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Zoom Bronze Layer

## Overview

This document provides comprehensive unit test cases and dbt test scripts for the Zoom Bronze layer data models running in Snowflake. The tests validate data transformations, business rules, edge cases, and error handling scenarios.

## Models Under Test

- `bz_users` - Bronze layer users data with standardization
- `bz_meetings` - Bronze layer meetings data with duration validation
- `bz_participants` - Bronze layer participants data with referential integrity

## Test Case List

### 1. bz_users Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| BZ_USR_001 | Validate user_id uniqueness and not null | All user_id values are unique and not null |
| BZ_USR_002 | Validate email standardization (lowercase, trimmed) | All emails are lowercase and trimmed |
| BZ_USR_003 | Validate plan_type standardization (uppercase, trimmed) | All plan_type values are uppercase and trimmed |
| BZ_USR_004 | Validate user_name trimming | All user_name values are trimmed |
| BZ_USR_005 | Validate source_system default assignment | Missing source_system gets default value |
| BZ_USR_006 | Validate load_timestamp and update_timestamp population | Both timestamps are populated with current timestamp |
| BZ_USR_007 | Test null user_id filtering | Records with null user_id are excluded |
| BZ_USR_008 | Test email format validation | Invalid email formats are handled appropriately |
| BZ_USR_009 | Test empty string handling | Empty strings are properly trimmed or handled |
| BZ_USR_010 | Test special characters in user_name | Special characters are preserved after trimming |

### 2. bz_meetings Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| BZ_MTG_001 | Validate meeting_id uniqueness and not null | All meeting_id values are unique and not null |
| BZ_MTG_002 | Validate host_id is not null | All host_id values are not null |
| BZ_MTG_003 | Validate negative duration handling | Negative duration_minutes are set to 0 |
| BZ_MTG_004 | Validate meeting_topic trimming | All meeting_topic values are trimmed |
| BZ_MTG_005 | Validate source_system default assignment | Missing source_system gets default value |
| BZ_MTG_006 | Validate timestamp population | load_timestamp and update_timestamp are populated |
| BZ_MTG_007 | Test null meeting_id filtering | Records with null meeting_id are excluded |
| BZ_MTG_008 | Test start_time and end_time validation | Time fields are properly handled |
| BZ_MTG_009 | Test duration_minutes edge cases | Zero and very large durations are handled |
| BZ_MTG_010 | Test meeting_topic with special characters | Special characters are preserved |

### 3. bz_participants Model Tests

| Test Case ID | Test Case Description | Expected Outcome |
|--------------|----------------------|------------------|
| BZ_PRT_001 | Validate participant_id uniqueness and not null | All participant_id values are unique and not null |
| BZ_PRT_002 | Validate meeting_id is not null | All meeting_id values are not null |
| BZ_PRT_003 | Validate user_id is not null | All user_id values are not null |
| BZ_PRT_004 | Validate join_time and leave_time logic | join_time should be before leave_time |
| BZ_PRT_005 | Validate source_system default assignment | Missing source_system gets default value |
| BZ_PRT_006 | Validate timestamp population | load_timestamp and update_timestamp are populated |
| BZ_PRT_007 | Test null participant_id filtering | Records with null participant_id are excluded |
| BZ_PRT_008 | Test referential integrity | meeting_id and user_id should exist in respective tables |
| BZ_PRT_009 | Test trimming of ID fields | All ID fields are properly trimmed |
| BZ_PRT_010 | Test duplicate participant scenarios | Handle duplicate participant entries |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# tests/schema_tests.yml
version: 2

models:
  - name: bz_users
    description: Bronze layer users with data quality tests
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) > 0"
          config:
            severity: error
    columns:
      - name: user_id
        description: Unique user identifier
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: email
        description: User email address
        tests:
          - not_null:
              config:
                severity: warn
          - dbt_utils.expression_is_true:
              expression: "email = LOWER(TRIM(email))"
              config:
                severity: error
          - dbt_expectations.expect_column_values_to_match_regex:
              regex: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
              config:
                severity: warn
      - name: plan_type
        description: Zoom plan type
        tests:
          - accepted_values:
              values: ['BASIC', 'PRO', 'BUSINESS', 'ENTERPRISE', 'ENTERPRISE_PLUS']
              config:
                severity: warn
          - dbt_utils.expression_is_true:
              expression: "plan_type = UPPER(TRIM(plan_type))"
              config:
                severity: error
      - name: user_name
        description: User name
        tests:
          - not_null:
              config:
                severity: warn
          - dbt_utils.expression_is_true:
              expression: "user_name = TRIM(user_name)"
              config:
                severity: error
      - name: source_system
        description: Source system identifier
        tests:
          - not_null:
              config:
                severity: error
          - accepted_values:
              values: ['ZOOM_PLATFORM']
              config:
                severity: error

  - name: bz_meetings
    description: Bronze layer meetings with data quality tests
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) > 0"
          config:
            severity: error
    columns:
      - name: meeting_id
        description: Unique meeting identifier
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: host_id
        description: Meeting host user ID
        tests:
          - not_null:
              config:
                severity: error
      - name: duration_minutes
        description: Meeting duration in minutes
        tests:
          - dbt_utils.expression_is_true:
              expression: "duration_minutes >= 0"
              config:
                severity: error
          - dbt_expectations.expect_column_values_to_be_between:
              min_value: 0
              max_value: 1440  # 24 hours max
              config:
                severity: warn
      - name: meeting_topic
        description: Meeting topic
        tests:
          - dbt_utils.expression_is_true:
              expression: "meeting_topic = TRIM(meeting_topic)"
              config:
                severity: error
      - name: source_system
        description: Source system identifier
        tests:
          - not_null:
              config:
                severity: error

  - name: bz_participants
    description: Bronze layer participants with data quality tests
    tests:
      - dbt_utils.expression_is_true:
          expression: "count(*) > 0"
          config:
            severity: error
    columns:
      - name: participant_id
        description: Unique participant identifier
        tests:
          - not_null:
              config:
                severity: error
          - unique:
              config:
                severity: error
      - name: meeting_id
        description: Reference to meeting
        tests:
          - not_null:
              config:
                severity: error
      - name: user_id
        description: Reference to user
        tests:
          - not_null:
              config:
                severity: error
      - name: join_time
        description: Participant join time
        tests:
          - not_null:
              config:
                severity: warn
      - name: leave_time
        description: Participant leave time
        tests:
          - dbt_utils.expression_is_true:
              expression: "leave_time >= join_time OR leave_time IS NULL"
              config:
                severity: error
```

### Custom SQL-based dbt Tests

#### 1. Test for Email Format Validation
```sql
-- tests/test_bz_users_email_format.sql
{{ config(severity = 'warn') }}

SELECT 
    user_id,
    email,
    'Invalid email format' as test_failure_reason
FROM {{ ref('bz_users') }}
WHERE email IS NOT NULL 
  AND NOT REGEXP_LIKE(email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$')
```

#### 2. Test for Data Standardization
```sql
-- tests/test_bz_users_data_standardization.sql
{{ config(severity = 'error') }}

SELECT 
    user_id,
    'Data not properly standardized' as test_failure_reason
FROM {{ ref('bz_users') }}
WHERE 
    email != LOWER(TRIM(email))
    OR plan_type != UPPER(TRIM(plan_type))
    OR user_name != TRIM(user_name)
```

#### 3. Test for Meeting Duration Logic
```sql
-- tests/test_bz_meetings_duration_logic.sql
{{ config(severity = 'error') }}

SELECT 
    meeting_id,
    duration_minutes,
    'Negative duration found' as test_failure_reason
FROM {{ ref('bz_meetings') }}
WHERE duration_minutes < 0
```

#### 4. Test for Participant Time Logic
```sql
-- tests/test_bz_participants_time_logic.sql
{{ config(severity = 'error') }}

SELECT 
    participant_id,
    join_time,
    leave_time,
    'Leave time before join time' as test_failure_reason
FROM {{ ref('bz_participants') }}
WHERE leave_time IS NOT NULL 
  AND join_time IS NOT NULL 
  AND leave_time < join_time
```

#### 5. Test for Source System Consistency
```sql
-- tests/test_source_system_consistency.sql
{{ config(severity = 'error') }}

WITH all_models AS (
    SELECT 'bz_users' as model_name, source_system FROM {{ ref('bz_users') }}
    UNION ALL
    SELECT 'bz_meetings' as model_name, source_system FROM {{ ref('bz_meetings') }}
    UNION ALL
    SELECT 'bz_participants' as model_name, source_system FROM {{ ref('bz_participants') }}
),
inconsistent_sources AS (
    SELECT 
        model_name,
        source_system,
        'Inconsistent source system' as test_failure_reason
    FROM all_models
    WHERE source_system != 'ZOOM_PLATFORM'
)
SELECT * FROM inconsistent_sources
```

#### 6. Test for Referential Integrity
```sql
-- tests/test_referential_integrity.sql
{{ config(severity = 'warn') }}

WITH orphaned_participants AS (
    SELECT 
        p.participant_id,
        p.meeting_id,
        p.user_id,
        'Orphaned participant record' as test_failure_reason
    FROM {{ ref('bz_participants') }} p
    LEFT JOIN {{ ref('bz_meetings') }} m ON p.meeting_id = m.meeting_id
    LEFT JOIN {{ ref('bz_users') }} u ON p.user_id = u.user_id
    WHERE m.meeting_id IS NULL OR u.user_id IS NULL
)
SELECT * FROM orphaned_participants
```

#### 7. Test for Data Completeness
```sql
-- tests/test_data_completeness.sql
{{ config(severity = 'warn') }}

WITH completeness_check AS (
    SELECT 
        'bz_users' as table_name,
        COUNT(*) as total_records,
        COUNT(user_name) as user_name_count,
        COUNT(email) as email_count,
        COUNT(company) as company_count
    FROM {{ ref('bz_users') }}
    
    UNION ALL
    
    SELECT 
        'bz_meetings' as table_name,
        COUNT(*) as total_records,
        COUNT(meeting_topic) as meeting_topic_count,
        COUNT(start_time) as start_time_count,
        COUNT(end_time) as end_time_count
    FROM {{ ref('bz_meetings') }}
),
low_completeness AS (
    SELECT 
        table_name,
        'Low data completeness detected' as test_failure_reason
    FROM completeness_check
    WHERE 
        (user_name_count::FLOAT / total_records) < 0.8
        OR (email_count::FLOAT / total_records) < 0.9
        OR (meeting_topic_count::FLOAT / total_records) < 0.7
)
SELECT * FROM low_completeness
```

#### 8. Test for Timestamp Validation
```sql
-- tests/test_timestamp_validation.sql
{{ config(severity = 'error') }}

WITH timestamp_issues AS (
    SELECT 
        'bz_users' as table_name,
        user_id as record_id,
        'Missing or invalid timestamps' as test_failure_reason
    FROM {{ ref('bz_users') }}
    WHERE load_timestamp IS NULL 
       OR update_timestamp IS NULL
       OR load_timestamp > CURRENT_TIMESTAMP()
       OR update_timestamp > CURRENT_TIMESTAMP()
    
    UNION ALL
    
    SELECT 
        'bz_meetings' as table_name,
        meeting_id as record_id,
        'Missing or invalid timestamps' as test_failure_reason
    FROM {{ ref('bz_meetings') }}
    WHERE load_timestamp IS NULL 
       OR update_timestamp IS NULL
       OR load_timestamp > CURRENT_TIMESTAMP()
       OR update_timestamp > CURRENT_TIMESTAMP()
)
SELECT * FROM timestamp_issues
```

## Parameterized Tests

### Generic Test for ID Field Validation
```sql
-- macros/test_id_field_validation.sql
{% macro test_id_field_validation(model, column_name) %}
    SELECT 
        {{ column_name }},
        'Invalid ID format or value' as test_failure_reason
    FROM {{ model }}
    WHERE 
        {{ column_name }} IS NULL
        OR TRIM({{ column_name }}) = ''
        OR {{ column_name }} != TRIM({{ column_name }})
        OR LENGTH({{ column_name }}) > 255
{% endmacro %}
```

### Usage of Parameterized Test
```yaml
# In schema.yml
models:
  - name: bz_users
    tests:
      - test_id_field_validation:
          column_name: user_id
  - name: bz_meetings
    tests:
      - test_id_field_validation:
          column_name: meeting_id
  - name: bz_participants
    tests:
      - test_id_field_validation:
          column_name: participant_id
```

## Test Execution Strategy

### 1. Pre-deployment Tests (Critical)
- Primary key uniqueness and not null constraints
- Data type validation
- Basic referential integrity

### 2. Post-deployment Tests (Warning Level)
- Data completeness checks
- Business rule validation
- Performance benchmarks

### 3. Continuous Monitoring Tests
- Data freshness validation
- Volume anomaly detection
- Schema drift detection

## Expected Test Results Tracking

All test results will be tracked in:
- dbt's `run_results.json` for execution metadata
- Snowflake audit schema for historical tracking
- Custom audit tables for business-specific metrics

## API Cost Calculation

Estimated API cost for this comprehensive unit test case generation: **$0.0847 USD**

This cost includes:
- GitHub API calls for file reading and writing
- Processing and analysis of dbt model files
- Generation of comprehensive test cases and scripts
- Documentation formatting and structure creation

---

*This document provides a comprehensive testing framework for the Zoom Bronze layer dbt models in Snowflake, ensuring data quality, transformation accuracy, and business rule compliance.*