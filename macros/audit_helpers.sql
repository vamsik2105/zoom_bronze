{% macro log_table_stats(table_name) %}
  {% set query %}
    SELECT 
      '{{ table_name }}' as table_name,
      COUNT(*) as row_count,
      COUNT(DISTINCT customer_id) as unique_customers,
      CURRENT_TIMESTAMP() as stats_timestamp
    FROM {{ table_name }}
  {% endset %}
  
  {% if execute %}
    {% set results = run_query(query) %}
    {% for row in results %}
      {{ log("Table Stats - " ~ row[0] ~ ": " ~ row[1] ~ " rows, " ~ row[2] ~ " unique customers", info=true) }}
    {% endfor %}
  {% endif %}
{% endmacro %}

{% macro validate_email(email_column) %}
  REGEXP_LIKE({{ email_column }}, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
{% endmacro %}

{% macro generate_audit_columns() %}
  CURRENT_TIMESTAMP() AS created_at,
  CURRENT_TIMESTAMP() AS updated_at,
  '{{ run_started_at }}' AS dbt_run_timestamp,
  '{{ invocation_id }}' AS dbt_invocation_id
{% endmacro %}
