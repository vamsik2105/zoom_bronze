{% macro calculate_data_quality_score(table_name, primary_key) %}
    CASE 
        WHEN {{ primary_key }} IS NULL THEN 0.0
        ELSE (
            CASE WHEN {{ primary_key }} IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN load_timestamp IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN update_timestamp IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN source_system IS NOT NULL THEN 0.25 ELSE 0 END
        )
    END
{% endmacro %}
