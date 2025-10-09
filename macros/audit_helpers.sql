{% macro log_audit_event(table_name, operation_type, record_count=none, status='SUCCESS') %}
  {% if execute and this.name != 'audit_log' %}
    {% set audit_sql %}
      INSERT INTO {{ ref('audit_log') }} (
        source_table, 
        operation_type, 
        record_count, 
        process_status, 
        created_at, 
        updated_at
      ) 
      VALUES (
        '{{ table_name }}', 
        '{{ operation_type }}', 
        {% if record_count %}{{ record_count }}{% else %}NULL{% endif %}, 
        '{{ status }}', 
        CURRENT_TIMESTAMP(), 
        CURRENT_TIMESTAMP()
      )
    {% endset %}
    
    {% do run_query(audit_sql) %}
  {% endif %}
{% endmacro %}

{% macro get_audit_columns() %}
  'PROCESSED' AS process_status,
  CURRENT_TIMESTAMP() AS created_at,
  CURRENT_TIMESTAMP() AS updated_at
{% endmacro %}

{% macro bronze_table_template(source_name, table_name) %}
  {{ config(
      materialized='table',
      tags=['bronze', table_name],
      pre_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (source_table, operation_type, process_status, created_at) VALUES ('" + table_name + "', 'LOAD_START', 'RUNNING', CURRENT_TIMESTAMP()){% endif %}",
      post_hook="{% if this.name != 'audit_log' %}INSERT INTO {{ ref('audit_log') }} (source_table, operation_type, record_count, process_status, updated_at) VALUES ('" + table_name + "', 'LOAD_COMPLETE', (SELECT COUNT(*) FROM {{ this }}), 'SUCCESS', CURRENT_TIMESTAMP()){% endif %}"
  ) }}

  SELECT 
      *,
      {{ get_audit_columns() }}
  FROM {{ source(source_name, table_name) }}
{% endmacro %}

{% macro test_row_count_matches_source(model_name, source_name, table_name) %}
  SELECT 
    CASE 
      WHEN source_count != model_count THEN 1 
      ELSE 0 
    END AS row_count_mismatch
  FROM (
    SELECT 
      (SELECT COUNT(*) FROM {{ source(source_name, table_name) }}) AS source_count,
      (SELECT COUNT(*) FROM {{ ref(model_name) }}) AS model_count
  )
  HAVING row_count_mismatch = 1
{% endmacro %}

{% macro validate_audit_log_entries() %}
  {% set tables = ['bz_users', 'bz_meetings', 'bz_participants', 'bz_feature_usage', 'bz_webinars', 'bz_support_tickets', 'bz_licenses', 'bz_billing_events'] %}
  
  SELECT 
    source_table,
    COUNT(*) as audit_entries,
    MAX(updated_at) as last_updated
  FROM {{ ref('audit_log') }}
  WHERE source_table IN ({% for table in tables %}'{{ table }}'{% if not loop.last %},{% endif %}{% endfor %})
  GROUP BY source_table
  HAVING COUNT(*) < 2  -- Should have at least LOAD_START and LOAD_COMPLETE
{% endmacro %}
