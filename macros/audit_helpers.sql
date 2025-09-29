{% macro log_model_start(model_name) %}
    {% set query %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message
        )
        SELECT
            '{{ model_name }}' as model_name,
            CURRENT_TIMESTAMP() as process_timestamp,
            'STARTED' as status,
            'Processing started for {{ model_name }}' as message
    {% endset %}
    
    {% do run_query(query) %}
{% endmacro %}

{% macro log_model_completion(model_name) %}
    {% set query %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message
        )
        SELECT
            '{{ model_name }}' as model_name,
            CURRENT_TIMESTAMP() as process_timestamp,
            'COMPLETED' as status,
            'Processing completed for {{ model_name }}' as message
    {% endset %}
    
    {% do run_query(query) %}
{% endmacro %}

{% macro log_model_error(model_name, error_message) %}
    {% set query %}
        INSERT INTO {{ ref('audit_log') }} (
            model_name,
            process_timestamp,
            status,
            message
        )
        SELECT
            '{{ model_name }}' as model_name,
            CURRENT_TIMESTAMP() as process_timestamp,
            'ERROR' as status,
            '{{ error_message }}' as message
    {% endset %}
    
    {% do run_query(query) %}
{% endmacro %}
