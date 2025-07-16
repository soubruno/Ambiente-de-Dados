-- Staging model para gêneros com análise detalhada

WITH genres_base AS (
    SELECT 
        id as genre_id,
        TRIM(name) as genre_name
    FROM steam_source.genres
    WHERE name IS NOT NULL 
      AND TRIM(name) != ''
),

genres_with_stats AS (
    SELECT 
        g.genre_id,
        g.genre_name,
        
        -- Contagem total de jogos
        COUNT(gg.game_id) as total_games,
        COUNT(CASE WHEN gg.is_primary THEN 1 END) as primary_genre_games,
        
        -- Estatísticas de preço
        AVG(gm.current_price) as avg_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gm.current_price) as median_price,
        MIN(gm.current_price) as min_price,
        MAX(gm.current_price) as max_price,
        
        -- Estatísticas de qualidade
        AVG(gm.metacritic_score) as avg_metacritic_score,
        AVG(gm.user_score) as avg_user_score,
        AVG(CASE 
            WHEN (gm.positive_reviews + gm.negative_reviews) > 0 
            THEN (gm.positive_reviews::DECIMAL / (gm.positive_reviews + gm.negative_reviews)) * 100
            ELSE NULL
        END) as avg_review_percent,
        
        -- Estatísticas de popularidade
        AVG((gm.estimated_owners_min + gm.estimated_owners_max) / 2) as avg_estimated_owners,
        SUM(gm.positive_reviews + gm.negative_reviews) as total_reviews,
        
        -- Estatísticas de engajamento
        AVG(gm.average_playtime_forever) as avg_playtime_forever,
        AVG(gm.average_playtime_two_weeks) as avg_playtime_two_weeks,
        AVG(gm.median_playtime_forever) as avg_median_playtime,
        
        -- Estatísticas de conteúdo
        AVG(gm.achievements_count) as avg_achievements,
        AVG(gm.dlc_count) as avg_dlc_count,
        
        -- Distribuição por faixa etária
        COUNT(CASE WHEN gm.required_age = 0 THEN 1 END) as all_ages_count,
        COUNT(CASE WHEN gm.required_age BETWEEN 1 AND 12 THEN 1 END) as kids_count,
        COUNT(CASE WHEN gm.required_age BETWEEN 13 AND 17 THEN 1 END) as teen_count,
        COUNT(CASE WHEN gm.required_age >= 18 THEN 1 END) as mature_count,
        
        -- Percentual de jogos gratuitos
        ROUND((COUNT(CASE WHEN gm.is_free THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2) as free_games_percent,
        
        -- Dados mais recentes
        MAX(gm.release_date) as latest_release_date,
        MIN(gm.release_date) as earliest_release_date

    FROM genres_base g
    LEFT JOIN steam_source.game_genres gg 
        ON g.genre_id = gg.genre_id
    LEFT JOIN steam_source.games gm 
        ON gg.game_id = gm.app_id
    GROUP BY g.genre_id, g.genre_name
),

genres_with_rankings AS (
    SELECT 
        *,
        
        -- Rankings baseados em diferentes métricas
        ROW_NUMBER() OVER (ORDER BY total_games DESC) as games_count_rank,
        ROW_NUMBER() OVER (ORDER BY avg_review_percent DESC NULLS LAST) as quality_rank,
        ROW_NUMBER() OVER (ORDER BY avg_estimated_owners DESC NULLS LAST) as popularity_rank,
        ROW_NUMBER() OVER (ORDER BY avg_playtime_forever DESC NULLS LAST) as engagement_rank,
        ROW_NUMBER() OVER (ORDER BY avg_price DESC NULLS LAST) as price_rank,
        
        -- Score composto de sucesso do gênero
        CASE 
            WHEN total_games > 0 AND avg_estimated_owners > 0 AND avg_review_percent > 0
            THEN (
                LOG(total_games) * 0.3 +
                LOG(avg_estimated_owners) * 0.4 +
                (avg_review_percent / 100.0) * 0.3
            )
            ELSE 0
        END as genre_success_score

    FROM genres_with_stats
    WHERE total_games > 0
)

SELECT 
    genre_id,
    genre_name,
    total_games,
    primary_genre_games,
    
    -- Preços formatados
    ROUND(COALESCE(avg_price, 0)::numeric, 2) as avg_price,
    ROUND(COALESCE(median_price, 0)::numeric, 2) as median_price,
    ROUND(COALESCE(min_price, 0)::numeric, 2) as min_price,
    ROUND(COALESCE(max_price, 0)::numeric, 2) as max_price,
    
    -- Qualidade formatada
    ROUND(COALESCE(avg_metacritic_score, 0)::numeric, 1) as avg_metacritic_score,
    ROUND(COALESCE(avg_user_score, 0)::numeric, 2) as avg_user_score,
    ROUND(COALESCE(avg_review_percent, 0)::numeric, 2) as avg_review_percent,
    
    -- Popularidade formatada
    ROUND(COALESCE(avg_estimated_owners, 0)::numeric, 0) as avg_estimated_owners,
    total_reviews,
    
    -- Engajamento formatado
    ROUND(COALESCE(avg_playtime_forever, 0)::numeric, 0) as avg_playtime_forever,
    ROUND(COALESCE(avg_playtime_two_weeks, 0)::numeric, 0) as avg_playtime_two_weeks,
    ROUND(COALESCE(avg_median_playtime, 0)::numeric, 0) as avg_median_playtime,
    
    -- Conteúdo formatado
    ROUND(COALESCE(avg_achievements, 0)::numeric, 1) as avg_achievements,
    ROUND(COALESCE(avg_dlc_count, 0)::numeric, 1) as avg_dlc_count,
    
    -- Distribuição demográfica
    all_ages_count,
    kids_count,
    teen_count,
    mature_count,
    free_games_percent,
    
    -- Datas
    latest_release_date,
    earliest_release_date,
    
    -- Classificação do gênero
    CASE 
        WHEN total_games >= 500 THEN 'Major Genre'
        WHEN total_games >= 100 THEN 'Popular Genre'
        WHEN total_games >= 20 THEN 'Standard Genre'
        ELSE 'Niche Genre'
    END as genre_category,
    
    -- Perfil de preço do gênero
    CASE 
        WHEN avg_price = 0 THEN 'Free-to-Play'
        WHEN avg_price <= 10 THEN 'Budget'
        WHEN avg_price <= 30 THEN 'Standard'
        WHEN avg_price <= 60 THEN 'Premium'
        ELSE 'Luxury'
    END as price_profile,
    
    -- Rankings
    games_count_rank,
    quality_rank,
    popularity_rank,
    engagement_rank,
    price_rank,
    
    -- Score final
    ROUND(genre_success_score::numeric, 4) as genre_success_score,
    
    CURRENT_TIMESTAMP as loaded_at

FROM genres_with_rankings
ORDER BY genre_success_score DESC
