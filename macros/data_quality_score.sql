{% macro calculate_data_quality_score(table_alias) %}
  CASE 
    WHEN {{ table_alias }}.record_status = 'error' THEN 0.0
    ELSE (
      CASE WHEN {{ table_alias }}.load_timestamp IS NOT NULL THEN 0.25 ELSE 0.0 END +
      CASE WHEN {{ table_alias }}.update_timestamp IS NOT NULL THEN 0.25 ELSE 0.0 END +
      CASE WHEN {{ table_alias }}.source_system IS NOT NULL THEN 0.25 ELSE 0.0 END +
      0.25 -- Base score for valid record
    )
  END
{% endmacro %}
