-- FACT_GAMES: TABELA FATO CENTRAL - ALTA E FINA (NOVO MODELO SIMPLIFICADO)
-- Apenas métricas numéricas e chaves estrangeiras (sem relacionamentos complexos)

WITH games_base AS (
    SELECT 
        app_id,
        name,
        release_date,
        current_price,
        estimated_owners_min,
        estimated_owners_max,
        metacritic_score,
        user_score,
        positive_reviews,
        negative_reviews,
        average_playtime_forever,
        average_playtime_two_weeks,
        median_playtime_forever,
        median_playtime_two_weeks,
        recommendations,
        achievements_count,
        dlc_count,
        is_free,
        controller_support,
        quality_score,
        popularity_score,
        price_category,
        total_reviews,
        review_score_percent
    FROM {{ ref('stg_games') }}
    WHERE app_id IS NOT NULL
),

-- Lookup das dimensões
dim_keys AS (
    SELECT 
        gb.app_id,
        COALESCE(dg.game_key, -1) as game_key,
        COALESCE(dd.date_key, 99991231) as release_date_key,
        COALESCE(dps.price_segment_key, -1) as price_segment_key,
        
        -- Desenvolvedores primários
        COALESCE(dev.developer_key, -1) as primary_developer_key,
        
        -- Publishers primários  
        COALESCE(pub.publisher_key, -1) as primary_publisher_key,
        
        -- Gêneros primários
        COALESCE(gen.genre_key, -1) as primary_genre_key,
        
        -- Categorias primárias
        COALESCE(cat.category_key, -1) as primary_category_key,
        
        -- Tags primárias
        COALESCE(tag.tag_key, -1) as primary_tag_key,
        
        -- Idiomas primários
        COALESCE(lang.language_key, -1) as primary_language_key
        
    FROM games_base gb
    
    -- Game dimension
    LEFT JOIN {{ ref('dim_game') }} dg ON gb.app_id = dg.game_id
    
    -- Date dimension
    LEFT JOIN {{ ref('dim_date') }} dd ON TO_CHAR(gb.release_date, 'YYYYMMDD')::INT = dd.date_key
    
    -- Price segment dimension
    LEFT JOIN {{ ref('dim_price_segment') }} dps ON gb.price_category = dps.name
    
    -- Primary developer (first one listed)
    LEFT JOIN {{ ref('stg_game_developers') }} gd ON gb.app_id = gd.game_id AND gd.is_primary_developer = TRUE
    LEFT JOIN {{ ref('dim_developer') }} dev ON gd.developer_id = dev.developer_id
    
    -- Primary publisher (first one listed)
    LEFT JOIN {{ ref('stg_game_publishers') }} gp ON gb.app_id = gp.game_id AND gp.is_primary_publisher = TRUE
    LEFT JOIN {{ ref('dim_publisher') }} pub ON gp.publisher_id = pub.publisher_id
    
    -- Primary genre
    LEFT JOIN {{ ref('stg_game_genres') }} gg ON gb.app_id = gg.game_id AND gg.is_primary = TRUE
    LEFT JOIN {{ ref('dim_genre') }} gen ON gg.genre_id = gen.genre_id
    
    -- Primary category (most common one)
    LEFT JOIN (
        SELECT game_id, category_id,
               ROW_NUMBER() OVER (PARTITION BY game_id ORDER BY category_id) as rn
        FROM {{ ref('stg_game_categories') }}
    ) gc ON gb.app_id = gc.game_id AND gc.rn = 1
    LEFT JOIN {{ ref('dim_category') }} cat ON gc.category_id = cat.category_id
    
    -- Primary tag (most voted one)
    LEFT JOIN (
        SELECT game_id, tag_id,
               ROW_NUMBER() OVER (PARTITION BY game_id ORDER BY tag_votes DESC) as rn
        FROM {{ ref('stg_game_tags') }}
    ) gt ON gb.app_id = gt.game_id AND gt.rn = 1
    LEFT JOIN {{ ref('dim_tag') }} tag ON gt.tag_id = tag.tag_id
    
    -- Primary language (English if available, otherwise first one)
    LEFT JOIN (
        SELECT game_id, language_id,
               ROW_NUMBER() OVER (
                   PARTITION BY game_id 
                   ORDER BY CASE WHEN is_english THEN 0 ELSE 1 END, language_id
               ) as rn
        FROM {{ ref('stg_game_supported_languages') }}
    ) gl ON gb.app_id = gl.game_id AND gl.rn = 1
    LEFT JOIN {{ ref('dim_language') }} lang ON gl.language_id = lang.language_id
),

-- Contadores de relacionamentos
relationship_counts AS (
    SELECT 
        gb.app_id,
        COALESCE(dev_count.total_developers, 1) as total_developers_count,
        COALESCE(pub_count.total_publishers, 1) as total_publishers_count,
        COALESCE(gen_count.total_genres, 1) as total_genres_count,
        COALESCE(cat_count.total_categories, 0) as total_categories_count,
        COALESCE(tag_count.total_tags, 0) as total_tags_count,
        COALESCE(lang_count.total_languages, 0) as total_languages_count
    FROM games_base gb
    
    -- Contagem de desenvolvedores
    LEFT JOIN (
        SELECT game_id, COUNT(*) as total_developers
        FROM {{ ref('stg_game_developers') }}
        GROUP BY game_id
    ) dev_count ON gb.app_id = dev_count.game_id
    
    -- Contagem de publishers
    LEFT JOIN (
        SELECT game_id, COUNT(*) as total_publishers
        FROM {{ ref('stg_game_publishers') }}
        GROUP BY game_id
    ) pub_count ON gb.app_id = pub_count.game_id
    
    -- Contagem de gêneros
    LEFT JOIN (
        SELECT game_id, COUNT(*) as total_genres
        FROM {{ ref('stg_game_genres') }}
        GROUP BY game_id
    ) gen_count ON gb.app_id = gen_count.game_id
    
    -- Contagem de categorias
    LEFT JOIN (
        SELECT game_id, COUNT(*) as total_categories
        FROM {{ ref('stg_game_categories') }}
        GROUP BY game_id
    ) cat_count ON gb.app_id = cat_count.game_id
    
    -- Contagem de tags
    LEFT JOIN (
        SELECT game_id, COUNT(*) as total_tags
        FROM {{ ref('stg_game_tags') }}
        GROUP BY game_id
    ) tag_count ON gb.app_id = tag_count.game_id
    
    -- Contagem de idiomas
    LEFT JOIN (
        SELECT game_id, COUNT(*) as total_languages
        FROM {{ ref('stg_game_supported_languages') }}
        GROUP BY game_id
    ) lang_count ON gb.app_id = lang_count.game_id
)

-- SELEÇÃO FINAL - ESTRUTURA ALTA E FINA
SELECT 
    ROW_NUMBER() OVER (ORDER BY gb.app_id) as fact_key,
    
    -- CHAVES ESTRANGEIRAS (dimensões principais)
    dk.game_key,
    dk.release_date_key,
    dk.price_segment_key,
    dk.primary_developer_key,
    dk.primary_publisher_key,
    dk.primary_genre_key,
    dk.primary_category_key,
    dk.primary_tag_key,
    dk.primary_language_key,
    
    -- MÉTRICAS PURAS (apenas números e medidas)
    
    -- Métricas de preço
    COALESCE(gb.current_price, 0) as current_price,
    COALESCE(gb.current_price, 0) as original_price, 
    0.0 as discount_percent,  -- Placeholder
    
    -- Métricas de popularidade
    COALESCE(gb.estimated_owners_min, 0) as estimated_owners_min,
    COALESCE(gb.estimated_owners_max, 0) as estimated_owners_max,
    COALESCE((gb.estimated_owners_min + gb.estimated_owners_max) / 2, 0) as estimated_owners_avg,
    0 as peak_ccu,
    
    -- Métricas de avaliação
    COALESCE(gb.metacritic_score, 0) as metacritic_score,
    COALESCE(gb.user_score, 0) as user_score,
    COALESCE(gb.positive_reviews, 0) as positive_reviews,
    COALESCE(gb.negative_reviews, 0) as negative_reviews,
    COALESCE(gb.total_reviews, 0) as total_reviews,
    COALESCE(gb.review_score_percent, 0) as review_score_percent,
    
    -- Métricas de engajamento  
    COALESCE(gb.average_playtime_forever, 0) as average_playtime_forever,
    COALESCE(gb.average_playtime_two_weeks, 0) as average_playtime_two_weeks,
    COALESCE(gb.median_playtime_forever, 0) as median_playtime_forever,
    COALESCE(gb.median_playtime_two_weeks, 0) as median_playtime_two_weeks,
    COALESCE(gb.recommendations, 0) as recommendations,
    
    -- Contadores simples (relacionamentos agregados)
    rc.total_developers_count::SMALLINT,
    rc.total_publishers_count::SMALLINT,
    rc.total_genres_count::SMALLINT,
    rc.total_categories_count::SMALLINT,
    rc.total_tags_count::SMALLINT,
    rc.total_languages_count::SMALLINT,
    
    -- Flags simples (apenas boolean)
    COALESCE(gb.achievements_count > 0, FALSE) as has_achievements,
    COALESCE(gb.dlc_count > 0, FALSE) as has_dlc,
    FALSE as has_trading_cards,  
    FALSE as has_workshop,  
    COALESCE(rc.total_languages_count > 1, FALSE) as has_multiple_languages,
    CASE WHEN gb.controller_support != 'None' THEN TRUE ELSE FALSE END as has_controller_support,
    FALSE as is_vr_supported,  
    FALSE as is_early_access, 
    
    -- Scores calculados (apenas números)
    COALESCE(gb.popularity_score, 0) as popularity_score,
    COALESCE(gb.average_playtime_forever * 0.01, 0) as engagement_score,  -- Baseado no tempo de jogo
    COALESCE(gb.estimated_owners_min * gb.current_price * 0.0001, 0) as commercial_success_score,
    COALESCE(gb.quality_score, 0) as quality_score,
    
    -- Rankings (números simples)
    ROW_NUMBER() OVER (ORDER BY gb.popularity_score DESC NULLS LAST) as global_popularity_rank,
    0 as genre_popularity_rank,  -- Será calculado em views
    ROW_NUMBER() OVER (ORDER BY gb.quality_score DESC NULLS LAST) as quality_rank_overall,
    
    -- Metadados mínimos
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at

FROM games_base gb
INNER JOIN dim_keys dk ON gb.app_id = dk.app_id
INNER JOIN relationship_counts rc ON gb.app_id = rc.app_id
WHERE dk.game_key != -1
