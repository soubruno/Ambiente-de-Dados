-- Staging model para desenvolvedores com análise de performance

WITH developers_base AS (
    SELECT 
        id as developer_id,
        TRIM(name) as developer_name
    FROM steam_source.developers
    WHERE name IS NOT NULL 
      AND TRIM(name) != ''
),

developers_with_stats AS (
    SELECT 
        d.developer_id,
        d.developer_name,
        
        -- Portfolio básico
        COUNT(gd.game_id) as total_games,
        MIN(g.release_date) as first_release_date,
        MAX(g.release_date) as latest_release_date,
        
        -- Estatísticas financeiras
        AVG(g.current_price) as avg_price,
        SUM(CASE WHEN g.is_free THEN 0 ELSE g.current_price END) as total_revenue_potential,
        COUNT(CASE WHEN g.is_free THEN 1 END) as free_games_count,
        COUNT(CASE WHEN NOT g.is_free THEN 1 END) as paid_games_count,
        
        -- Estatísticas de qualidade
        AVG(g.metacritic_score) as avg_metacritic_score,
        AVG(g.user_score) as avg_user_score,
        SUM(g.positive_reviews) as total_positive_reviews,
        SUM(g.negative_reviews) as total_negative_reviews,
        AVG(CASE 
            WHEN (g.positive_reviews + g.negative_reviews) > 0 
            THEN (g.positive_reviews::DECIMAL / (g.positive_reviews + g.negative_reviews)) * 100
            ELSE NULL
        END) as avg_review_percent,
        
        -- Estatísticas de popularidade
        AVG((g.estimated_owners_min + g.estimated_owners_max) / 2) as avg_estimated_owners,
        SUM((g.estimated_owners_min + g.estimated_owners_max) / 2) as total_estimated_owners,
        MAX((g.estimated_owners_min + g.estimated_owners_max) / 2) as biggest_hit_owners,
        
        -- Estatísticas de engajamento
        AVG(g.average_playtime_forever) as avg_playtime_forever,
        AVG(g.average_playtime_two_weeks) as avg_playtime_two_weeks,
        AVG(g.achievements_count) as avg_achievements,
        
        -- Análise de conteúdo
        AVG(g.dlc_count) as avg_dlc_count,
        SUM(g.dlc_count) as total_dlc_count,
        
        -- Distribuição por idade
        ROUND((COUNT(CASE WHEN g.required_age = 0 THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2) as all_ages_percent,
        ROUND((COUNT(CASE WHEN g.required_age >= 18 THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2) as mature_percent

    FROM developers_base d
    LEFT JOIN steam_source.game_developers gd 
        ON d.developer_id = gd.developer_id
    LEFT JOIN steam_source.games g 
        ON gd.game_id = g.app_id
    GROUP BY d.developer_id, d.developer_name
),

developers_with_analysis AS (
    SELECT 
        *,
        
        -- Experiência do desenvolvedor (anos no mercado)
        CASE 
            WHEN first_release_date IS NOT NULL AND latest_release_date IS NOT NULL
            THEN EXTRACT(YEAR FROM latest_release_date) - EXTRACT(YEAR FROM first_release_date) + 1
            ELSE NULL
        END as years_active,
        
        -- Produtividade (jogos por ano)
        CASE 
            WHEN first_release_date IS NOT NULL AND latest_release_date IS NOT NULL 
                AND EXTRACT(YEAR FROM latest_release_date) > EXTRACT(YEAR FROM first_release_date)
            THEN total_games::DECIMAL / (EXTRACT(YEAR FROM latest_release_date) - EXTRACT(YEAR FROM first_release_date) + 1)
            ELSE total_games::DECIMAL
        END as games_per_year,
        
        -- Estratégia de monetização
        CASE 
            WHEN free_games_count = total_games THEN 'Free-to-Play Only'
            WHEN free_games_count = 0 THEN 'Paid Only'
            WHEN free_games_count::DECIMAL / total_games > 0.7 THEN 'Mostly Free'
            WHEN paid_games_count::DECIMAL / total_games > 0.7 THEN 'Mostly Paid'
            ELSE 'Mixed Strategy'
        END as monetization_strategy,
        
        -- Score de reputação
        CASE 
            WHEN total_positive_reviews + total_negative_reviews > 0
            THEN (total_positive_reviews::DECIMAL / (total_positive_reviews + total_negative_reviews)) * 100
            ELSE NULL
        END as overall_reputation_score,
        
        -- Classificação do desenvolvedor
        CASE 
            WHEN total_games >= 50 THEN 'Major Developer'
            WHEN total_games >= 10 THEN 'Established Developer'
            WHEN total_games >= 3 THEN 'Regular Developer'
            ELSE 'Indie Developer'
        END as developer_tier

    FROM developers_with_stats
    WHERE total_games > 0
)

SELECT 
    developer_id,
    developer_name,
    total_games,
    
    -- Datas formatadas
    first_release_date,
    latest_release_date,
    years_active,
    ROUND(COALESCE(games_per_year, 0)::numeric, 2) as games_per_year,
    
    -- Financeiro formatado
    ROUND(COALESCE(avg_price, 0)::numeric, 2) as avg_price,
    ROUND(COALESCE(total_revenue_potential, 0)::numeric, 2) as total_revenue_potential,
    free_games_count,
    paid_games_count,
    monetization_strategy,
    
    -- Qualidade formatada
    ROUND(COALESCE(avg_metacritic_score, 0)::numeric, 1) as avg_metacritic_score,
    ROUND(COALESCE(avg_user_score, 0)::numeric, 2) as avg_user_score,
    total_positive_reviews,
    total_negative_reviews,
    ROUND(COALESCE(avg_review_percent, 0)::numeric, 2) as avg_review_percent,
    ROUND(COALESCE(overall_reputation_score, 0)::numeric, 2) as overall_reputation_score,
    
    -- Popularidade formatada
    ROUND(COALESCE(avg_estimated_owners, 0)::numeric, 0) as avg_estimated_owners,
    ROUND(COALESCE(total_estimated_owners, 0)::numeric, 0) as total_estimated_owners,
    ROUND(COALESCE(biggest_hit_owners, 0)::numeric, 0) as biggest_hit_owners,
    
    -- Engajamento formatado
    ROUND(COALESCE(avg_playtime_forever, 0)::numeric, 0) as avg_playtime_forever,
    ROUND(COALESCE(avg_playtime_two_weeks, 0)::numeric, 0) as avg_playtime_two_weeks,
    ROUND(COALESCE(avg_achievements, 0)::numeric, 1) as avg_achievements,
    
    -- Conteúdo formatado
    ROUND(COALESCE(avg_dlc_count, 0)::numeric, 1) as avg_dlc_count,
    total_dlc_count,
    
    -- Demografia
    all_ages_percent,
    mature_percent,
    
    -- Classificações
    developer_tier,
    
    -- Rankings
    ROW_NUMBER() OVER (ORDER BY total_games DESC) as games_count_rank,
    ROW_NUMBER() OVER (ORDER BY overall_reputation_score DESC NULLS LAST) as reputation_rank,
    ROW_NUMBER() OVER (ORDER BY total_estimated_owners DESC NULLS LAST) as popularity_rank,
    ROW_NUMBER() OVER (ORDER BY avg_metacritic_score DESC NULLS LAST) as quality_rank,
    
    CURRENT_TIMESTAMP as loaded_at

FROM developers_with_analysis
ORDER BY total_estimated_owners DESC NULLS LAST
