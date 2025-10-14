{{ config(
    materialized='table'
) }}

SELECT 
    'engagement_001' as engagement_id,
    CURRENT_DATE() as summary_date,
    'ORG_001' as organization_id,
    0 as total_meetings,
    0.0 as average_participation_rate,
    0 as total_chat_messages,
    0 as screen_share_sessions,
    0 as total_reactions,
    0 as qa_interactions,
    0 as poll_responses,
    0.0 as average_attention_score,
    CURRENT_DATE() as load_date,
    CURRENT_DATE() as update_date,
    'SILVER' as source_system
WHERE 1=0
