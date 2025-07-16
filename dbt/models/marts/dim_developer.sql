-- DIM_DEVELOPER: Dimensão de desenvolvedores - BAIXA E LARGA (muitos atributos descritivos)

WITH developers_base AS (
    SELECT 
        developer_id,
        developer_name as name,
        total_games,
        avg_metacritic_score,
        avg_user_score,
        total_positive_reviews,
        total_negative_reviews,
        avg_price,
        first_release_date,
        latest_release_date,
        years_active,
        games_per_year,
        free_games_count,
        paid_games_count,
        all_ages_percent,
        mature_percent
    FROM {{ ref('stg_developers') }}
    WHERE developer_id IS NOT NULL
      AND developer_name IS NOT NULL
),

developers_enriched AS (
    SELECT 
        *,
        
        -- ANÁLISES DE MERCADO E POSICIONAMENTO
        CASE 
            WHEN total_games >= 50 THEN 'Major'
            WHEN total_games >= 20 THEN 'AAA'
            WHEN total_games >= 5 THEN 'Mid-tier'
            ELSE 'Indie'
        END as developer_tier,
        
        CASE 
            WHEN years_active >= 15 THEN 'Dominant'
            WHEN years_active >= 10 THEN 'Established'
            WHEN years_active >= 5 THEN 'Growing'
            ELSE 'Emerging'
        END as market_presence,
        
        CASE 
            WHEN avg_metacritic_score >= 80 THEN 'Revolutionary'
            WHEN avg_metacritic_score >= 70 THEN 'Innovative'
            WHEN avg_metacritic_score >= 60 THEN 'Iterative'
            ELSE 'Conservative'
        END as innovation_level,
        
        -- ESTRATÉGIAS DE NEGÓCIO
        CASE 
            WHEN free_games_count > paid_games_count THEN 'F2P'
            WHEN games_per_year >= 3 THEN 'Early Access'
            ELSE 'Traditional'
        END as business_model,
        
        CASE 
            WHEN free_games_count > 0 THEN 'Microtransactions'
            WHEN avg_price > 40 THEN 'DLC-heavy'
            ELSE 'One-time'
        END as monetization_approach,
        
        CASE 
            WHEN games_per_year >= 5 THEN 'Prolific'
            WHEN games_per_year >= 2 THEN 'Regular'
            ELSE 'Infrequent'
        END as release_frequency,
        
        -- INFORMAÇÕES DESCRITIVAS
        CASE 
            WHEN total_games >= 100 THEN 'Enterprise'
            WHEN total_games >= 50 THEN 'Large'
            WHEN total_games >= 20 THEN 'Medium'
            WHEN total_games >= 5 THEN 'Small'
            ELSE 'Solo'
        END as company_size,
        
        -- ANÁLISES DE SUCESSO E QUALIDADE
        CASE 
            WHEN avg_metacritic_score >= 80 AND total_games >= 10 THEN 
                ROUND((avg_metacritic_score * 0.6 + (total_games / 10.0) * 20 + (years_active / 2.0) * 20)::NUMERIC, 2)
            WHEN avg_metacritic_score > 0 THEN 
                ROUND(avg_metacritic_score::NUMERIC, 2)
            ELSE 50.0
        END as reputation_score,
        
        CASE 
            WHEN total_positive_reviews > total_negative_reviews * 3 THEN 
                ROUND(((total_positive_reviews::DECIMAL / GREATEST(total_positive_reviews + total_negative_reviews, 1)) * 100)::NUMERIC, 2)
            ELSE 50.0
        END as success_rate_percent,
        
        CASE 
            WHEN avg_metacritic_score >= 85 THEN 'Excellent'
            WHEN avg_metacritic_score >= 75 THEN 'Good'
            WHEN avg_metacritic_score >= 65 THEN 'Basic'
            ELSE 'Poor'
        END as post_launch_support_quality
    FROM developers_base
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY developer_id) as developer_key,
    developer_id,
    name,
    
    -- INFORMAÇÕES DESCRITIVAS (BAIXA E LARGA)
    '' as company_description,  -- Placeholder
    '' as headquarters_location,  -- Placeholder
    EXTRACT(YEAR FROM first_release_date)::INT as founding_year,
    company_size,
    '' as website_url,  -- Placeholder
    
    -- Especialização e foco
    CASE 
        WHEN mature_percent > 50 THEN 'Mature Games'
        WHEN all_ages_percent > 70 THEN 'Family Games'
        ELSE 'General Audience'
    END as primary_specialization,
    
    '' as secondary_specializations,  -- Placeholder
    'PC' as typical_platforms,  -- Assumindo PC por ser Steam
    '' as common_engines,  -- Placeholder
    
    -- MÉTRICAS CALCULADAS DO DESENVOLVEDOR
    total_games,
    total_games as total_games_as_primary,  -- Assumindo que são primários
    0 as total_games_as_secondary,  -- Placeholder
    ROUND(avg_metacritic_score::NUMERIC, 2) as avg_metacritic_score,
    ROUND(avg_user_score::NUMERIC, 2) as avg_user_score,
    total_positive_reviews,
    total_negative_reviews,
    ROUND(avg_price::NUMERIC, 2) as avg_price,
    0.0 as avg_playtime,  -- Placeholder
    
    -- ANÁLISES DE MERCADO E POSICIONAMENTO
    developer_tier,
    market_presence,
    reputation_score,
    innovation_level,
    
    -- Estratégias de negócio
    business_model,
    monetization_approach,
    release_frequency,
    
    -- Relacionamentos típicos
    '' as frequent_publishers,  -- Placeholder
    '' as typical_genres,  -- Placeholder
    '' as common_categories,  -- Placeholder
    
    -- ANÁLISES DE SUCESSO E QUALIDADE
    success_rate_percent,
    CASE 
        WHEN avg_metacritic_score >= 80 THEN total_games / 3
        WHEN avg_metacritic_score >= 70 THEN total_games / 5
        ELSE 0
    END as hit_games_count,
    
    CASE 
        WHEN games_per_year <= 1 THEN 24
        WHEN games_per_year <= 2 THEN 18
        WHEN games_per_year <= 4 THEN 12
        ELSE 6
    END as avg_development_time_months,
    
    post_launch_support_quality,
    
    years_active,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at

FROM developers_enriched

UNION ALL

-- Registro padrão para desenvolvedores desconhecidos
SELECT 
    -1 as developer_key,
    -1 as developer_id,
    'Unknown Developer' as name,
    
    -- INFORMAÇÕES DESCRITIVAS
    'Developer information not available' as company_description,
    'Unknown' as headquarters_location,
    1970 as founding_year,
    'Unknown' as company_size,
    '' as website_url,
    
    -- Especialização e foco
    'Unknown' as primary_specialization,
    '' as secondary_specializations,
    'Unknown' as typical_platforms,
    '' as common_engines,
    
    -- MÉTRICAS CALCULADAS DO DESENVOLVEDOR
    0 as total_games,
    0 as total_games_as_primary,
    0 as total_games_as_secondary,
    0.0 as avg_metacritic_score,
    0.0 as avg_user_score,
    0 as total_positive_reviews,
    0 as total_negative_reviews,
    0.0 as avg_price,
    0.0 as avg_playtime,
    
    -- ANÁLISES DE MERCADO E POSICIONAMENTO
    'Unknown' as developer_tier,
    'Unknown' as market_presence,
    0.0 as reputation_score,
    'Unknown' as innovation_level,
    
    -- Estratégias de negócio
    'Unknown' as business_model,
    'Unknown' as monetization_approach,
    'Unknown' as release_frequency,
    
    -- Relacionamentos típicos
    '' as frequent_publishers,
    '' as typical_genres,
    '' as common_categories,
    
    -- ANÁLISES DE SUCESSO E QUALIDADE
    0.0 as success_rate_percent,
    0 as hit_games_count,
    0 as avg_development_time_months,
    'Unknown' as post_launch_support_quality,
    0 as years_active,
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at
