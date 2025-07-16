-- DIM_CATEGORY: Dimensão de categorias

WITH categories_base AS (
    SELECT 
        category_id,
        category_name,
        category_size,
        total_games,
        avg_price,
        min_price,
        max_price,
        avg_metacritic_score,
        avg_user_score,
        avg_review_percent,
        avg_estimated_owners,
        avg_playtime,
        free_games_percent
    FROM {{ ref('stg_categories') }}
    WHERE category_id IS NOT NULL
      AND category_name IS NOT NULL
),

categories_final AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY category_id) as category_key,
        category_id,
        category_name,
        category_name as category_name_clean,
        category_size as category_type,
        total_games,
        avg_price,
        min_price,
        max_price,
        avg_metacritic_score,
        avg_user_score,
        avg_review_percent as avg_review_score,
        avg_estimated_owners,
        avg_playtime,
        free_games_percent,
        category_size,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
    FROM categories_base
)

SELECT * FROM categories_final
