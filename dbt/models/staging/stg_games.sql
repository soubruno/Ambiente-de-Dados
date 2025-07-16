-- Staging model para jogos com limpeza e transformações básicas

WITH games_base AS (
    SELECT *
    FROM steam_source.games
),

games_cleaned AS (
    SELECT 
        app_id,
        TRIM(name) as name,
        
        -- Data de lançamento tratada
        CASE 
            WHEN release_date IS NULL THEN NULL
            WHEN release_date < '1970-01-01' THEN NULL
            WHEN release_date > CURRENT_DATE + INTERVAL '1 year' THEN NULL
            ELSE release_date
        END as release_date,
        
        -- Estimativas de proprietários
        COALESCE(estimated_owners_min, 0) as estimated_owners_min,
        COALESCE(estimated_owners_max, 0) as estimated_owners_max,
        
        -- Cálculo da média de proprietários estimados
        CASE 
            WHEN estimated_owners_min IS NOT NULL AND estimated_owners_max IS NOT NULL 
            THEN (estimated_owners_min + estimated_owners_max) / 2
            ELSE COALESCE(estimated_owners_min, estimated_owners_max, 0)
        END as estimated_owners_avg,
        
        -- Preço tratado
        CASE 
            WHEN current_price < 0 THEN 0
            WHEN current_price > 999.99 THEN 999.99
            ELSE COALESCE(current_price, 0)
        END as current_price,
        
        currency_id,
        COALESCE(peak_ccu, 0) as peak_ccu,
        COALESCE(required_age, 0) as required_age,
        COALESCE(dlc_count, 0) as dlc_count,
        
        -- Descrições limpas
        NULLIF(TRIM(about), '') as about,
        NULLIF(TRIM(short_description), '') as short_description,
        
        -- URLs validadas
        CASE 
            WHEN header_image_url LIKE 'http%' THEN header_image_url
            ELSE NULL
        END as header_image_url,
        
        CASE 
            WHEN website_url LIKE 'http%' THEN website_url
            ELSE NULL
        END as website_url,
        
        CASE 
            WHEN support_url LIKE 'http%' THEN support_url
            ELSE NULL
        END as support_url,
        
        -- Scores tratados
        CASE 
            WHEN metacritic_score BETWEEN 0 AND 100 THEN metacritic_score
            ELSE NULL
        END as metacritic_score,
        
        CASE 
            WHEN metacritic_url LIKE 'http%' THEN metacritic_url
            ELSE NULL
        END as metacritic_url,
        
        CASE 
            WHEN user_score BETWEEN 0.0 AND 10.0 THEN user_score
            ELSE NULL
        END as user_score,
        
        -- Reviews tratadas
        COALESCE(positive_reviews, 0) as positive_reviews,
        COALESCE(negative_reviews, 0) as negative_reviews,
        
        -- Outros campos
        COALESCE(achievements_count, 0) as achievements_count,
        COALESCE(recommendations, 0) as recommendations,
        COALESCE(average_playtime_forever, 0) as average_playtime_forever,
        COALESCE(average_playtime_two_weeks, 0) as average_playtime_two_weeks,
        COALESCE(median_playtime_forever, 0) as median_playtime_forever,
        COALESCE(median_playtime_two_weeks, 0) as median_playtime_two_weeks,
        
        COALESCE(game_status, 'Unknown') as game_status,
        COALESCE(is_free, FALSE) as is_free,
        COALESCE(controller_support, 'Unknown') as controller_support
        
    FROM games_base
    WHERE name IS NOT NULL
      AND name != ''
)

SELECT 
    *,
    
    -- Campos calculados
    positive_reviews + negative_reviews as total_reviews,
    
    -- Percentual de reviews positivas
    CASE 
        WHEN (positive_reviews + negative_reviews) > 0 
        THEN ROUND(((positive_reviews::DECIMAL / (positive_reviews + negative_reviews)) * 100)::numeric, 2)
        ELSE NULL
    END as review_score_percent,
    
    -- Classificação de preço
    CASE 
        WHEN current_price = 0 THEN 'Free'
        WHEN current_price <= 9.99 THEN 'Budget'
        WHEN current_price <= 19.99 THEN 'Economy'
        WHEN current_price <= 39.99 THEN 'Standard'
        WHEN current_price <= 59.99 THEN 'Premium'
        WHEN current_price <= 79.99 THEN 'AAA'
        ELSE 'Luxury'
    END as price_category,
    
    -- Classificação por idade
    CASE 
        WHEN required_age = 0 THEN 'All Ages'
        WHEN required_age <= 12 THEN 'Kids'
        WHEN required_age <= 17 THEN 'Teen'
        ELSE 'Mature'
    END as age_category,
    
    -- Score de popularidade simples
    CASE 
        WHEN estimated_owners_avg > 0 AND (positive_reviews + negative_reviews) > 0
        THEN LOG(estimated_owners_avg) * (positive_reviews::DECIMAL / (positive_reviews + negative_reviews))
        ELSE 0
    END as popularity_score,
    
    -- Fator de tendência (últimas 2 semanas vs forever)
    CASE 
        WHEN average_playtime_forever > 0 AND average_playtime_two_weeks > 0
        THEN ROUND(((average_playtime_two_weeks::DECIMAL / average_playtime_forever) * 100)::numeric, 2)
        ELSE NULL
    END as trend_factor_percent,
    
    -- Qualidade geral (combinação de scores)
    CASE 
        WHEN metacritic_score IS NOT NULL AND user_score IS NOT NULL
        THEN ROUND((((metacritic_score / 100.0) * 0.6 + (user_score / 10.0) * 0.4) * 100)::numeric, 2)
        WHEN metacritic_score IS NOT NULL
        THEN metacritic_score
        WHEN user_score IS NOT NULL
        THEN ROUND(((user_score / 10.0) * 100)::numeric, 2)
        ELSE NULL
    END as quality_score,
    
    -- Timestamp de carga
    CURRENT_TIMESTAMP as loaded_at

FROM games_cleaned
