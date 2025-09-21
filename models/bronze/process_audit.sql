{{ config(
 materialized='table',
 tags=['audit', 'bronze', 'monitoring']
) }}
WITH process_summary AS (
 SELECT 
 'customer_details_brz' AS model_name,
 'BRONZE' AS layer_name,
 'RAW.CUSTOMER_DETAILS' AS source_table,
 'CUSTOMER_DETAILS_BRZ' AS target_table,
 CURRENT_TIMESTAMP() AS execution_time,
 
 -- Count metrics from source
 (SELECT COUNT(*) FROM {{ var('source_schema') }}.CUSTOMER_DETAILS) AS source_record_count,
 
 -- Count metrics from target (this model)
 (SELECT COUNT(*) FROM {{ this.schema }}.CUSTOMER_DETAILS_BRZ 
 WHERE {{ this.schema }}.CUSTOMER_DETAILS_BRZ.CUSTOMER_ID IS NOT NULL) AS target_record_count,
 
 -- Data quality metrics
 (SELECT COUNT(*) FROM {{ var('source_schema') }}.CUSTOMER_DETAILS 
 WHERE CUSTOMER_ID IS NULL) AS null_customer_id_count,
 
 (SELECT COUNT(*) FROM {{ var('source_schema') }}.CUSTOMER_DETAILS 
 WHERE CUSTOMER_NAME IS NULL OR TRIM(CUSTOMER_NAME) = '') AS null_customer_name_count,
 
 -- Process status
 CASE 
 WHEN (SELECT COUNT(*) FROM {{ var('source_schema') }}.CUSTOMER_DETAILS) > 0 THEN 'SUCCESS'
 ELSE 'NO_DATA'
 END AS overall_status,
 
 -- Audit information
 CURRENT_USER() AS executed_by,
 '{{ invocation_id }}' AS dbt_invocation_id
)
SELECT 
 model_name,
 layer_name,
 source_table,
 target_table,
 execution_time,
 source_record_count,
 target_record_count,
 null_customer_id_count,
 null_customer_name_count,
 overall_status,
 executed_by,
 dbt_invocation_id,
 
 -- Calculate data quality score
 CASE 
 WHEN source_record_count = 0 THEN 0
 ELSE ROUND(((source_record_count - null_customer_id_count) * 100.0 / source_record_count), 2)
 END AS data_quality_score_pct
 
FROM process_summary
