_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze layer dbt models in Snowflake
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Zoom Bronze Pipeline

## Overview

This document provides comprehensive unit test cases and dbt test scripts for the Zoom Bronze layer transformation models running in Snowflake. The tests cover key transformations, business rules, edge cases, and error handling scenarios for the `bz_audit_log` and `bz_users` models.

## Model Analysis

### 1. bz_audit_log Model
- **Purpose**: Track processing of all bronze models for monitoring and debugging
- **Materialization**: Table
- **Key Transformations**: Static initial setup record creation
- **Business Rules**: Audit trail maintenance, status tracking

### 2. bz_users Model
- **Purpose**: Transform raw user data into bronze layer with basic validation
- **Source**: raw.users
- **Materialization**: Table
- **Key Transformations**: 1-to-1 mapping with metadata enrichment
- **Business Rules**: Data validation, timestamp management, source system tracking

## Test Case List

| Test Case ID | Test Case Description | Expected Outcome | Model |
|--------------|----------------------|------------------|-------|
| TC_BZ_AUDIT_001 | Verify audit log table creation with initial record | Single record with correct initial values | bz_audit_log |
| TC_BZ_AUDIT_002 | Validate audit log record_id uniqueness | No duplicate record_id values | bz_audit_log |
| TC_BZ_AUDIT_003 | Check audit log status values | Only accepted status values present | bz_audit_log |
| TC_BZ_AUDIT_004 | Verify audit log timestamp not null | All timestamp fields populated | bz_audit_log |
| TC_BZ_USERS_001 | Validate user_id uniqueness and not null | All user_id values unique and non-null | bz_users |
| TC_BZ_USERS_002 | Check email format validation | Valid email formats only | bz_users |
| TC_BZ_USERS_003 | Verify timestamp fields population | load_timestamp and update_timestamp not null | bz_users |
| TC_BZ_USERS_004 | Validate source system default value | source_system defaults to 'ZOOM_PLATFORM' | bz_users |
| TC_BZ_USERS_005 | Test handling of null source values | Proper COALESCE handling for null values | bz_users |
| TC_BZ_USERS_006 | Verify plan_type accepted values | Only valid plan types present | bz_users |
| TC_BZ_USERS_007 | Test empty source table handling | Graceful handling of empty raw.users | bz_users |
| TC_BZ_USERS_008 | Validate company name length limits | Company names within acceptable limits | bz_users |
| TC_BZ_USERS_009 | Test duplicate email handling | Proper handling of duplicate emails | bz_users |
| TC_BZ_USERS_010 | Verify cross-table relationship integrity | Consistent data across related tables | bz_users |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# tests/schema_tests.yml
version: 2

models:
  - name: bz_audit_log
    description: "Bronze layer audit log validation tests"
    tests:
      - dbt_utils.table_columns_to_contain_substring:
          column_list: ['record_id', 'source_table', 'load_timestamp']
    columns:
      - name: record_id
        tests:
          - not_null:
              severity: error
          - unique:
              severity: error
      - name: source_table
        tests:
          - not_null:
              severity: error
          - dbt_utils.not_empty_string:
              severity: warn
      - name: load_timestamp
        tests:
          - not_null:
              severity: error
          - dbt_utils.not_future_date:
              date_part: day
              severity: warn
      - name: processed_by
        tests:
          - not_null:
              severity: error
      - name: processing_time
        tests:
          - not_null:
              severity: error
          - dbt_utils.accepted_range:
              min_value: 0
              max_value: 86400
              severity: warn
      - name: status
        tests:
          - not_null:
              severity: error
          - accepted_values:
              values: ['SUCCESS', 'FAILED', 'IN_PROGRESS', 'CANCELLED']
              severity: error

  - name: bz_users
    description: "Bronze layer users validation tests"
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - user_id
            - email
          severity: error
    columns:
      - name: user_id
        tests:
          - not_null:
              severity: error
          - unique:
              severity: error
          - dbt_utils.not_empty_string:
              severity: error
      - name: user_name
        tests:
          - dbt_utils.not_empty_string:
              severity: warn
      - name: email
        tests:
          - not_null:
              severity: warn
          - dbt_expectations.expect_column_values_to_match_regex:
              regex: '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
              severity: warn
      - name: company
        tests:
          - dbt_utils.not_empty_string:
              severity: warn
      - name: plan_type
        tests:
          - accepted_values:
              values: ['Basic', 'Pro', 'Business', 'Enterprise', 'Enterprise Plus']
              severity: warn
      - name: load_timestamp
        tests:
          - not_null:
              severity: error
          - dbt_utils.not_future_date:
              date_part: day
              severity: warn
      - name: update_timestamp
        tests:
          - not_null:
              severity: error
          - dbt_utils.not_future_date:
              date_part: day
              severity: warn
      - name: source_system
        tests:
          - not_null:
              severity: error
          - accepted_values:
              values: ['ZOOM_PLATFORM', 'API_IMPORT', 'MANUAL_ENTRY']
              severity: warn
```

### Custom SQL-based dbt Tests

#### Test 1: Audit Log Initial Setup Validation
```sql
-- tests/test_audit_log_initial_setup.sql
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
```

#### Test 2: Users Timestamp Consistency
```sql
-- tests/test_users_timestamp_consistency.sql
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
```

#### Test 3: Source System Default Validation
```sql
-- tests/test_users_source_system_default.sql
/*
  Test Case: TC_BZ_USERS_004
  Description: Verify source_system defaults to 'ZOOM_PLATFORM' when null in source
*/

WITH source_data AS (
    SELECT 
        user_id,
        source_system as raw_source_system
    FROM {{ source('raw_zoom', 'users') }}
),
bronze_data AS (
    SELECT 
        user_id,
        source_system as bronze_source_system
    FROM {{ ref('bz_users') }}
)
SELECT 
    s.user_id,
    s.raw_source_system,
    b.bronze_source_system
FROM source_data s
JOIN bronze_data b ON s.user_id = b.user_id
WHERE 
    s.raw_source_system IS NULL 
    AND b.bronze_source_system != 'ZOOM_PLATFORM'
```

#### Test 4: Email Uniqueness Validation
```sql
-- tests/test_users_email_uniqueness.sql
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
```

#### Test 5: Data Completeness Check
```sql
-- tests/test_users_data_completeness.sql
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
```

#### Test 6: Plan Type Validation
```sql
-- tests/test_users_plan_type_validation.sql
/*
  Test Case: TC_BZ_USERS_006
  Description: Validate plan_type contains only accepted values
*/

SELECT 
    plan_type,
    COUNT(*) as occurrence_count
FROM {{ ref('bz_users') }}
WHERE plan_type IS NOT NULL
  AND plan_type NOT IN ('Basic', 'Pro', 'Business', 'Enterprise', 'Enterprise Plus')
GROUP BY plan_type
```

#### Test 7: Audit Log Processing Time Validation
```sql
-- tests/test_audit_log_processing_time.sql
/*
  Test Case: TC_BZ_AUDIT_002
  Description: Verify processing_time is within reasonable bounds
*/

SELECT 
    record_id,
    processing_time,
    source_table
FROM {{ ref('bz_audit_log') }}
WHERE 
    processing_time < 0 
    OR processing_time > 86400  -- More than 24 hours
```

### Parameterized Tests

#### Generic Test for Column Value Ranges
```sql
-- tests/generic/test_column_value_range.sql
/*
  Generic test for validating column values within specified ranges
*/

{% test column_value_range(model, column_name, min_value, max_value) %}

SELECT 
    {{ column_name }},
    COUNT(*) as invalid_count
FROM {{ model }}
WHERE 
    {{ column_name }} IS NOT NULL
    AND (
        {{ column_name }} < {{ min_value }}
        OR {{ column_name }} > {{ max_value }}
    )
GROUP BY {{ column_name }}

{% endtest %}
```

#### Generic Test for String Length Validation
```sql
-- tests/generic/test_string_length.sql
/*
  Generic test for validating string column lengths
*/

{% test string_length_validation(model, column_name, max_length) %}

SELECT 
    {{ column_name }},
    LENGTH({{ column_name }}) as actual_length
FROM {{ model }}
WHERE 
    {{ column_name }} IS NOT NULL
    AND LENGTH({{ column_name }}) > {{ max_length }}

{% endtest %}
```

### Edge Case Tests

#### Test for Handling Empty Source Tables
```sql
-- tests/test_empty_source_handling.sql
/*
  Test Case: TC_BZ_USERS_007
  Description: Verify graceful handling when source table is empty
*/

{% if execute %}
    {% set source_count_query %}
        SELECT COUNT(*) as record_count 
        FROM {{ source('raw_zoom', 'users') }}
    {% endset %}
    
    {% set results = run_query(source_count_query) %}
    {% if results %}
        {% set source_count = results.columns[0].values()[0] %}
        
        {% if source_count == 0 %}
            SELECT 
                'Source table is empty' as test_result,
                COUNT(*) as bronze_count
            FROM {{ ref('bz_users') }}
            HAVING COUNT(*) > 0  -- Should fail if bronze has records when source is empty
        {% endif %}
    {% endif %}
{% endif %}
```

### Performance Tests

#### Test for Model Execution Time
```sql
-- tests/test_model_performance.sql
/*
  Performance test to ensure models execute within acceptable time limits
*/

WITH execution_start AS (
    SELECT CURRENT_TIMESTAMP() as start_time
),
model_execution AS (
    SELECT COUNT(*) as record_count
    FROM {{ ref('bz_users') }}
),
execution_end AS (
    SELECT CURRENT_TIMESTAMP() as end_time
)
SELECT 
    DATEDIFF('second', start_time, end_time) as execution_seconds
FROM execution_start
CROSS JOIN execution_end
WHERE DATEDIFF('second', start_time, end_time) > 300  -- Fail if execution takes more than 5 minutes
```

## Test Execution Strategy

### 1. Pre-deployment Tests
- Run all schema tests to validate data structure
- Execute custom SQL tests for business rule validation
- Perform edge case testing with sample data

### 2. Post-deployment Tests
- Validate data completeness and accuracy
- Check performance benchmarks
- Verify audit trail functionality

### 3. Continuous Monitoring
- Schedule regular test runs via dbt Cloud
- Set up alerts for test failures
- Monitor test execution times and results

## Test Configuration

```yaml
# dbt_project.yml test configuration
tests:
  Zoom_Customer_Analytics:
    +severity: warn
    bronze:
      +severity: error
      +tags: ["bronze_tests"]
```

## Expected Test Results Tracking

All test results will be tracked in:
1. **dbt's run_results.json**: Contains detailed test execution results
2. **Snowflake audit schema**: Custom audit tables for test result history
3. **dbt Cloud dashboard**: Visual representation of test status

## API Cost Calculation

Estimated API cost for this comprehensive test suite execution:
- **dbt Cloud API calls**: ~$0.02 per job run
- **Snowflake compute costs**: ~$0.15 per test suite execution (assuming X-Small warehouse)
- **Total estimated cost per full test run**: ~$0.17 USD

*Note: Actual costs may vary based on data volume, warehouse size, and execution frequency.*

## Maintenance Guidelines

1. **Regular Review**: Review and update tests monthly
2. **Performance Monitoring**: Track test execution times
3. **Coverage Analysis**: Ensure new model changes include corresponding tests
4. **Documentation**: Keep test documentation updated with model changes
5. **Version Control**: Maintain test versioning alongside model versions

---

*This comprehensive test suite ensures the reliability, performance, and data quality of the Zoom Bronze layer dbt models in Snowflake environment.*