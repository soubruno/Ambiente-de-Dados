-- Staging model para categorias com enriquecimento

WITH categories_base AS (
    SELECT 
        id as category_id,
        TRIM(name) as category_name
    FROM steam_source.categories
    WHERE name IS NOT NULL 
      AND TRIM(name) != ''
),

categories_with_stats AS (
    SELECT 
        c.category_id,
        c.category_name,
        
        -- Contagem de jogos por categoria
        COUNT(gc.game_id) as total_games,
        
        -- Estatísticas de preço
        AVG(g.current_price) as avg_price,
        MIN(g.current_price) as min_price,
        MAX(g.current_price) as max_price,
        
        -- Estatísticas de avaliação
        AVG(g.metacritic_score) as avg_metacritic_score,
        AVG(g.user_score) as avg_user_score,
        AVG(CASE 
            WHEN (g.positive_reviews + g.negative_reviews) > 0 
            THEN (g.positive_reviews::DECIMAL / (g.positive_reviews + g.negative_reviews)) * 100
            ELSE NULL
        END) as avg_review_percent,
        
        -- Estatísticas de popularidade
        AVG((g.estimated_owners_min + g.estimated_owners_max) / 2) as avg_estimated_owners,
        AVG(g.average_playtime_forever) as avg_playtime,
        
        -- Percentual de jogos gratuitos
        ROUND((COUNT(CASE WHEN g.is_free THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2) as free_games_percent
        
    FROM categories_base c
    LEFT JOIN steam_source.game_categories gc 
        ON c.category_id = gc.category_id
    LEFT JOIN steam_source.games g 
        ON gc.game_id = g.app_id
    GROUP BY c.category_id, c.category_name
)

SELECT 
    category_id,
    category_name,
    total_games,
    
    -- Preços formatados
    ROUND(COALESCE(avg_price, 0)::numeric, 2) as avg_price,
    ROUND(COALESCE(min_price, 0)::numeric, 2) as min_price,
    ROUND(COALESCE(max_price, 0)::numeric, 2) as max_price,
    
    -- Scores formatados
    ROUND(COALESCE(avg_metacritic_score, 0)::numeric, 1) as avg_metacritic_score,
    ROUND(COALESCE(avg_user_score, 0)::numeric, 2) as avg_user_score,
    ROUND(COALESCE(avg_review_percent, 0)::numeric, 2) as avg_review_percent,
    
    -- Popularidade formatada
    ROUND(COALESCE(avg_estimated_owners, 0)::numeric, 0) as avg_estimated_owners,
    ROUND(COALESCE(avg_playtime, 0)::numeric, 0) as avg_playtime,
    
    free_games_percent,
    
    -- Classificação da categoria baseada no total de jogos
    CASE 
        WHEN total_games >= 1000 THEN 'Major'
        WHEN total_games >= 100 THEN 'Standard'
        WHEN total_games >= 10 THEN 'Minor'
        ELSE 'Niche'
    END as category_size,
    
    -- Score de popularidade da categoria
    CASE 
        WHEN total_games > 0 AND avg_estimated_owners > 0
        THEN LOG(total_games) * LOG(avg_estimated_owners)
        ELSE 0
    END as popularity_score,
    
    -- Ranking baseado em diversos fatores
    ROW_NUMBER() OVER (ORDER BY total_games DESC) as games_count_rank,
    ROW_NUMBER() OVER (ORDER BY avg_review_percent DESC) as quality_rank,
    ROW_NUMBER() OVER (ORDER BY avg_estimated_owners DESC) as popularity_rank,
    
    CURRENT_TIMESTAMP as loaded_at

FROM categories_with_stats
WHERE total_games > 0  -- Apenas categorias com jogos associados
