{% macro calculate_data_quality_score(table_name) %}
  CASE 
    WHEN {{ table_name }}.record_status = 'error' THEN 0.0
    ELSE (
      CASE WHEN {{ table_name }}.user_id IS NOT NULL THEN 0.2 ELSE 0.0 END +
      CASE WHEN {{ table_name }}.load_timestamp IS NOT NULL THEN 0.2 ELSE 0.0 END +
      CASE WHEN {{ table_name }}.update_timestamp IS NOT NULL THEN 0.2 ELSE 0.0 END +
      CASE WHEN {{ table_name }}.source_system IS NOT NULL THEN 0.2 ELSE 0.0 END +
      0.2 -- Base score for valid record
    )
  END
{% endmacro %}
