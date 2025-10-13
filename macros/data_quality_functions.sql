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

{% macro log_data_quality_error(error_type, source_table, source_column, error_description, error_value, record_id) %}
  INSERT INTO {{ target.schema }}.si_data_quality_errors (
    error_id, source_table, source_column, error_type, 
    error_description, error_value, expected_format, 
    record_identifier, error_timestamp, severity_level, 
    resolution_status, load_date, update_date, source_system
  ) VALUES (
    {{ dbt_utils.generate_surrogate_key([error_type, source_table, source_column, record_id]) }},
    '{{ source_table }}',
    '{{ source_column }}',
    '{{ error_type }}',
    '{{ error_description }}',
    '{{ error_value }}',
    'See validation rules',
    '{{ record_id }}',
    CURRENT_TIMESTAMP(),
    'HIGH',
    'OPEN',
    CURRENT_DATE(),
    CURRENT_DATE(),
    'DBT_TRANSFORMATION'
  )
{% endmacro %}
