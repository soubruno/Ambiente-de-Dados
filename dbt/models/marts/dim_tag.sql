-- DIM_TAG: Dimensão de tags conforme DDL do DW

WITH tags_base AS (
    SELECT 
        tag_id,
        tag_name,
        tag_name_clean,
        tag_category,
        tag_type,
        total_games,
        avg_votes_per_game,
        total_votes,
        avg_game_quality,
        avg_game_price,
        popularity_trend,
        niche_score,
        commercial_appeal,
        created_at,
        updated_at
    FROM {{ ref('stg_tags') }}
    WHERE tag_id IS NOT NULL
      AND tag_name IS NOT NULL
),

tags_final AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY tag_id) as tag_key,
        tag_id,
        tag_name,
        tag_name_clean,
        tag_category,
        tag_type,
        total_games,
        avg_votes_per_game,
        total_votes,
        avg_game_quality,
        avg_game_price,
        popularity_trend,
        niche_score,
        commercial_appeal,
        created_at,
        updated_at
    FROM tags_base
)

SELECT * FROM tags_final
