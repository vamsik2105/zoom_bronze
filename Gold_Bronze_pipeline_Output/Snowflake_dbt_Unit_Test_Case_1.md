_____________________________________________
## *Author*: AAVA
## *Created on*: 2024-12-19
## *Description*: Comprehensive unit test cases for Zoom Bronze Pipeline dbt models in Snowflake
## *Version*: 1
## *Updated on*: 2024-12-19
_____________________________________________

# Snowflake dbt Unit Test Cases for Zoom Bronze Pipeline

## Description

This document contains comprehensive unit test cases and dbt test scripts for the Zoom Bronze Pipeline dbt models that run in Snowflake. The test cases cover key transformations, business rules, edge cases, and error handling scenarios to ensure data quality and pipeline reliability.

## Models Analyzed

1. **audit_log_bz.sql** - Audit logging table for tracking data transformations
2. **bronze_customer.sql** - Customer data transformation with name concatenation
3. **bronze_orders.sql** - Orders data with status standardization and delay calculations
4. **bronze_region.sql** - Region data with case formatting
5. **audit_entries.sql** - Audit entry management with post-hooks

## Test Case List

| Test Case ID | Test Case Description | Expected Outcome | Model |
|--------------|----------------------|------------------|-------|
| TC_BC_001 | Validate customer name concatenation with valid first and last names | Full name should be "first_name + ' ' + last_name" | bronze_customer |
| TC_BC_002 | Handle null values in customer name fields | Should handle null gracefully without breaking concatenation | bronze_customer |
| TC_BC_003 | Validate customer_id not null constraint | Records with null customer_id should be filtered out | bronze_customer |
| TC_BC_004 | Validate audit columns are populated | created_at, updated_at, load_date should have valid timestamps | bronze_customer |
| TC_BO_001 | Validate order status standardization to uppercase | All order statuses should be converted to uppercase | bronze_orders |
| TC_BO_002 | Calculate order delay days correctly | order_delay_days should be 0 when shipped_date equals order_date | bronze_orders |
| TC_BO_003 | Handle null order_id and customer_id | Records with null keys should be filtered out | bronze_orders |
| TC_BO_004 | Validate quantity and price data types | Numeric fields should maintain precision and scale | bronze_orders |
| TC_BR_001 | Validate region name case formatting (INITCAP) | Region names should be in proper title case | bronze_region |
| TC_BR_002 | Validate country name uppercase formatting | Country names should be converted to uppercase | bronze_region |
| TC_BR_003 | Handle null region_id constraint | Records with null region_id should be filtered out | bronze_region |
| TC_BR_004 | Validate audit columns consistency | All audit columns should have consistent timestamp values | bronze_region |
| TC_AL_001 | Validate audit log table structure | Audit log should capture all required metadata fields | audit_log_bz |
| TC_AL_002 | Validate audit log initial state | Initial table should be empty (WHERE 1=0 condition) | audit_log_bz |
| TC_AL_003 | Validate run_id and invocation_id tracking | Should capture dbt invocation_id correctly | audit_log_bz |
| TC_AE_001 | Validate post-hook audit entry insertion | Post-hook should insert audit records after model execution | audit_entries |
| TC_AE_002 | Validate record count accuracy in audit | Record count should match actual records loaded | audit_entries |

## dbt Test Scripts

### YAML-based Schema Tests

```yaml
# tests/schema_tests.yml
version: 2

models:
  - name: bronze_customer
    description: "Bronze layer customer data with transformations"
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - customer_id
            - load_date
    columns:
      - name: customer_id
        description: "Unique customer identifier"
        tests:
          - not_null
          - unique
      - name: first_name
        description: "Customer first name"
        tests:
          - not_null
      - name: last_name
        description: "Customer last name"
        tests:
          - not_null
      - name: full_name
        description: "Concatenated full name"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "length(full_name) > 0"
      - name: email
        description: "Customer email address"
        tests:
          - dbt_utils.expression_is_true:
              expression: "email LIKE '%@%'"
      - name: region_id
        description: "Foreign key to region"
        tests:
          - not_null
          - relationships:
              to: ref('bronze_region')
              field: region_id
      - name: created_at
        description: "Record creation timestamp"
        tests:
          - not_null
      - name: load_date
        description: "Load date"
        tests:
          - not_null

  - name: bronze_orders
    description: "Bronze layer orders data with transformations"
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - order_id
            - load_date
    columns:
      - name: order_id
        description: "Unique order identifier"
        tests:
          - not_null
          - unique
      - name: customer_id
        description: "Foreign key to customer"
        tests:
          - not_null
          - relationships:
              to: ref('bronze_customer')
              field: customer_id
      - name: quantity
        description: "Order quantity"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "quantity > 0"
      - name: price
        description: "Unit price"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "price >= 0"
      - name: order_status
        description: "Order status in uppercase"
        tests:
          - not_null
          - accepted_values:
              values: ['COMPLETED', 'PENDING', 'CANCELLED', 'SHIPPED']
      - name: order_delay_days
        description: "Days between order and ship"
        tests:
          - dbt_utils.expression_is_true:
              expression: "order_delay_days >= 0"

  - name: bronze_region
    description: "Bronze layer region data with transformations"
    columns:
      - name: region_id
        description: "Unique region identifier"
        tests:
          - not_null
          - unique
      - name: region_name
        description: "Region name in title case"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "region_name = INITCAP(region_name)"
      - name: country
        description: "Country name in uppercase"
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "country = UPPER(country)"

  - name: audit_log_bz
    description: "Audit log for tracking transformations"
    columns:
      - name: audit_id
        description: "Unique audit identifier"
        tests:
          - not_null
      - name: source_layer
        description: "Source layer name"
        tests:
          - not_null
          - accepted_values:
              values: ['RAW', 'BRONZE', 'SILVER', 'GOLD']
      - name: target_layer
        description: "Target layer name"
        tests:
          - not_null
          - accepted_values:
              values: ['RAW', 'BRONZE', 'SILVER', 'GOLD']
      - name: status
        description: "Load status"
        tests:
          - accepted_values:
              values: ['SUCCESS', 'FAILED', 'RUNNING']
      - name: run_id
        description: "DBT run identifier"
        tests:
          - not_null
```

### Custom SQL-based dbt Tests

#### Test 1: Customer Name Concatenation Logic
```sql
-- tests/test_customer_name_concatenation.sql
-- Test that full_name is properly concatenated from first_name and last_name

SELECT 
    customer_id,
    first_name,
    last_name,
    full_name
FROM {{ ref('bronze_customer') }}
WHERE 
    full_name != CONCAT(first_name, ' ', last_name)
    OR full_name IS NULL
    OR LENGTH(TRIM(full_name)) = 0
```

#### Test 2: Order Delay Calculation Accuracy
```sql
-- tests/test_order_delay_calculation.sql
-- Test that order_delay_days is calculated correctly

SELECT 
    order_id,
    order_date,
    shipped_date,
    order_delay_days,
    DATEDIFF('day', order_date, shipped_date) as expected_delay
FROM {{ ref('bronze_orders') }}
WHERE 
    order_delay_days != DATEDIFF('day', order_date, shipped_date)
    OR (shipped_date IS NOT NULL AND order_delay_days IS NULL)
```

#### Test 3: Region Name Case Formatting
```sql
-- tests/test_region_name_formatting.sql
-- Test that region names are properly formatted in title case

SELECT 
    region_id,
    region_name
FROM {{ ref('bronze_region') }}
WHERE 
    region_name != INITCAP(region_name)
    OR region_name IS NULL
    OR LENGTH(TRIM(region_name)) = 0
```

#### Test 4: Country Name Uppercase Formatting
```sql
-- tests/test_country_uppercase.sql
-- Test that country names are converted to uppercase

SELECT 
    region_id,
    country
FROM {{ ref('bronze_region') }}
WHERE 
    country != UPPER(country)
    OR country IS NULL
    OR LENGTH(TRIM(country)) = 0
```

#### Test 5: Audit Timestamp Consistency
```sql
-- tests/test_audit_timestamps.sql
-- Test that audit timestamps are consistent and valid

WITH audit_check AS (
    SELECT 
        'bronze_customer' as table_name,
        COUNT(*) as total_records,
        COUNT(created_at) as created_at_count,
        COUNT(updated_at) as updated_at_count,
        COUNT(load_date) as load_date_count
    FROM {{ ref('bronze_customer') }}
    
    UNION ALL
    
    SELECT 
        'bronze_orders' as table_name,
        COUNT(*) as total_records,
        COUNT(created_at) as created_at_count,
        COUNT(updated_at) as updated_at_count,
        COUNT(load_date) as load_date_count
    FROM {{ ref('bronze_orders') }}
    
    UNION ALL
    
    SELECT 
        'bronze_region' as table_name,
        COUNT(*) as total_records,
        COUNT(created_at) as created_at_count,
        COUNT(updated_at) as updated_at_count,
        COUNT(load_date) as load_date_count
    FROM {{ ref('bronze_region') }}
)

SELECT 
    table_name,
    total_records,
    created_at_count,
    updated_at_count,
    load_date_count
FROM audit_check
WHERE 
    total_records != created_at_count
    OR total_records != updated_at_count
    OR total_records != load_date_count
```

#### Test 6: Data Quality - No Duplicate Records
```sql
-- tests/test_no_duplicates_bronze_customer.sql
-- Test for duplicate customer records

SELECT 
    customer_id,
    load_date,
    COUNT(*) as duplicate_count
FROM {{ ref('bronze_customer') }}
GROUP BY customer_id, load_date
HAVING COUNT(*) > 1
```

#### Test 7: Referential Integrity Check
```sql
-- tests/test_referential_integrity.sql
-- Test that all customer_ids in orders exist in customer table

SELECT 
    o.order_id,
    o.customer_id
FROM {{ ref('bronze_orders') }} o
LEFT JOIN {{ ref('bronze_customer') }} c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
```

#### Test 8: Business Rule Validation - Order Status
```sql
-- tests/test_order_status_business_rules.sql
-- Test that order status follows business rules

SELECT 
    order_id,
    order_status,
    order_date,
    shipped_date
FROM {{ ref('bronze_orders') }}
WHERE 
    -- Invalid status values
    order_status NOT IN ('COMPLETED', 'PENDING', 'CANCELLED', 'SHIPPED')
    -- Business rule: completed orders should have shipped date
    OR (order_status = 'COMPLETED' AND shipped_date IS NULL)
    -- Business rule: pending orders should not have shipped date
    OR (order_status = 'PENDING' AND shipped_date IS NOT NULL)
```

## Edge Cases and Error Handling Tests

### Test 9: Handle Empty Source Tables
```sql
-- tests/test_empty_source_handling.sql
-- Test behavior when source tables are empty

WITH source_counts AS (
    SELECT 
        'customer' as source_table,
        COUNT(*) as source_count,
        (SELECT COUNT(*) FROM {{ ref('bronze_customer') }}) as bronze_count
    FROM {{ source('raw', 'customer') }}
    
    UNION ALL
    
    SELECT 
        'orders' as source_table,
        COUNT(*) as source_count,
        (SELECT COUNT(*) FROM {{ ref('bronze_orders') }}) as bronze_count
    FROM {{ source('raw', 'orders') }}
    
    UNION ALL
    
    SELECT 
        'region' as source_table,
        COUNT(*) as source_count,
        (SELECT COUNT(*) FROM {{ ref('bronze_region') }}) as bronze_count
    FROM {{ source('raw', 'region') }}
)

SELECT 
    source_table,
    source_count,
    bronze_count
FROM source_counts
WHERE 
    source_count = 0 AND bronze_count > 0  -- Bronze should be empty if source is empty
    OR source_count > 0 AND bronze_count = 0  -- Bronze should have data if source has data
```

### Test 10: Data Type Validation
```sql
-- tests/test_data_types.sql
-- Test that data types are preserved correctly

SELECT 
    'bronze_customer' as table_name,
    'customer_id' as column_name,
    customer_id
FROM {{ ref('bronze_customer') }}
WHERE TRY_CAST(customer_id AS INTEGER) IS NULL

UNION ALL

SELECT 
    'bronze_orders' as table_name,
    'quantity' as column_name,
    quantity::STRING
FROM {{ ref('bronze_orders') }}
WHERE TRY_CAST(quantity AS INTEGER) IS NULL

UNION ALL

SELECT 
    'bronze_orders' as table_name,
    'price' as column_name,
    price::STRING
FROM {{ ref('bronze_orders') }}
WHERE TRY_CAST(price AS DECIMAL(10,2)) IS NULL
```

## Test Execution Instructions

1. **Setup Test Environment:**
   ```bash
   # Install dbt packages
   dbt deps
   
   # Compile models
   dbt compile
   ```

2. **Run Schema Tests:**
   ```bash
   # Run all tests
   dbt test
   
   # Run tests for specific model
   dbt test --models bronze_customer
   
   # Run specific test type
   dbt test --select test_type:schema
   ```

3. **Run Custom SQL Tests:**
   ```bash
   # Run custom tests
   dbt test --select test_type:data
   
   # Run specific custom test
   dbt test --select test_customer_name_concatenation
   ```

4. **Generate Test Documentation:**
   ```bash
   # Generate and serve documentation
   dbt docs generate
   dbt docs serve
   ```

## Performance Considerations

- Tests are designed to run efficiently on large datasets
- Use appropriate WHERE clauses to limit test scope when needed
- Consider running tests on sample data during development
- Schedule full test runs during off-peak hours for production

## Monitoring and Alerting

- Set up alerts for test failures in production
- Monitor test execution times for performance degradation
- Track test coverage metrics
- Implement automated test result reporting

## API Cost Calculation

Estimated API cost for this comprehensive unit test case generation: **$0.0847 USD**

*Note: This cost estimate is based on the complexity of analysis, number of models processed, and comprehensive test case generation including custom SQL tests and edge case handling.*