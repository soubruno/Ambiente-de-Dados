-- DIM_PUBLISHER: Dimensão de publishers

WITH publishers_base AS (
    SELECT 
        publisher_id,
        publisher_name,
        publisher_name_clean,
        publisher_category
    FROM {{ ref('stg_publishers') }}
    WHERE publisher_id IS NOT NULL
      AND publisher_name IS NOT NULL
),

publishers_enriched AS (
    SELECT 
        *,
        CASE
            WHEN publisher_category = 'AAA' THEN 'Large'
            WHEN publisher_category = 'Indie' THEN 'Small'
            ELSE 'Medium'
        END as publisher_size,
        CASE
            WHEN publisher_category = 'AAA' THEN 'High'
            WHEN publisher_category = 'Indie' THEN 'Low'
            ELSE 'Medium'
        END as market_presence
    FROM publishers_base
),

publishers_final AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY publisher_id) as publisher_key,
        publisher_id,
        publisher_name,
        publisher_name_clean,
        publisher_category,
        0 as total_games,
        0.0 as avg_game_price,
        0.0 as avg_metacritic_score,
        0.0 as avg_user_score,
        0 as total_reviews,
        0.0 as avg_review_score,
        0 as total_estimated_owners, 
        publisher_size,
        market_presence,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
    FROM publishers_enriched
),

default_record AS (
    SELECT 
        -1 as publisher_key,
        -1 as publisher_id,
        'Unknown Publisher' as publisher_name,
        'Unknown Publisher' as publisher_name_clean,
        'Unknown' as publisher_category,
        0 as total_games,
        0.0 as avg_game_price,
        0.0 as avg_metacritic_score,
        0.0 as avg_user_score,
        0 as total_reviews,
        0.0 as avg_review_score,
        0 as total_estimated_owners,
        'Unknown' as publisher_size,
        'Unknown' as market_presence,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
)

SELECT * FROM publishers_final
UNION ALL
SELECT * FROM default_record
