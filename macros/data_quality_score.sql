{% macro calculate_data_quality_score(table_alias='') %}
    CASE 
        WHEN {{ table_alias }}user_id IS NULL OR {{ table_alias }}user_name IS NULL OR {{ table_alias }}email IS NULL THEN 0.0
        WHEN NOT REGEXP_LIKE({{ table_alias }}email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN 0.5
        ELSE 1.0
    END
{% endmacro %}
