-- Staging model para jogos com áudio completo em idiomas específicos

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gfl.game_id,
        gfl.language_id,
        l.name as language_name,
        g.name as game_name,
        g.release_date,
        g.current_price,
        g.is_free,
        g.estimated_owners_min,
        g.estimated_owners_max
    FROM steam_source.game_full_audio_languages gfl
    JOIN steam_source.languages l ON gfl.language_id = l.id
    JOIN steam_source.games g ON gfl.game_id = g.app_id
    WHERE gfl.game_id IS NOT NULL 
      AND gfl.language_id IS NOT NULL
      AND l.name IS NOT NULL 
      AND TRIM(l.name) != ''
      AND g.name IS NOT NULL
),

language_classification AS (
    -- Classificação e categorização dos idiomas
    SELECT 
        *,
        -- Categorização por região/família
        CASE 
            WHEN LOWER(language_name) IN ('english', 'american english') THEN 'English'
            WHEN LOWER(language_name) IN ('spanish', 'spanish - spain', 'spanish - latin america') THEN 'Spanish'
            WHEN LOWER(language_name) IN ('portuguese', 'portuguese - brazil', 'brazilian') THEN 'Portuguese'
            WHEN LOWER(language_name) IN ('french', 'french - france') THEN 'French'
            WHEN LOWER(language_name) IN ('german', 'deutsch') THEN 'German'
            WHEN LOWER(language_name) IN ('italian', 'italiano') THEN 'Italian'
            WHEN LOWER(language_name) IN ('russian', 'русский') THEN 'Russian'
            WHEN LOWER(language_name) IN ('chinese', 'simplified chinese', 'traditional chinese', 'mandarin') THEN 'Chinese'
            WHEN LOWER(language_name) IN ('japanese', '日本語') THEN 'Japanese'
            WHEN LOWER(language_name) IN ('korean', '한국어') THEN 'Korean'
            ELSE 'Other'
        END as language_family,
        
        -- Mercado estimado
        CASE 
            WHEN LOWER(language_name) IN ('english', 'american english') THEN 'Global'
            WHEN LOWER(language_name) IN ('spanish', 'chinese', 'french', 'german', 'russian') THEN 'Major Regional'
            WHEN LOWER(language_name) IN ('portuguese', 'italian', 'japanese', 'korean') THEN 'Regional'
            ELSE 'Niche'
        END as market_tier,
        
        -- Prioridade do idioma para ordenação
        CASE 
            WHEN LOWER(language_name) IN ('english', 'american english') THEN 1
            WHEN LOWER(language_name) IN ('spanish', 'french', 'german') THEN 2
            WHEN LOWER(language_name) IN ('chinese', 'japanese', 'russian') THEN 3
            ELSE 4
        END as language_priority
    FROM source_data
),

language_rankings AS (
    -- Cálculos de rankings, posições e contagens
    SELECT
        *,
        -- Ordem/prioridade do idioma para o jogo
        ROW_NUMBER() OVER (
            PARTITION BY game_id 
            ORDER BY 
                language_priority,
                language_id
        ) as language_order,
        
        -- Contagem de idiomas com áudio completo para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_full_audio_languages,
        
        -- Contagem de jogos para o idioma
        COUNT(*) OVER (PARTITION BY language_id) as total_games_with_full_audio
    FROM language_classification
),

final_output AS (
    -- Finalizando com flags e ajustes adicionais
    SELECT
        game_id,
        language_id,
        language_name,
        language_order,
        total_full_audio_languages,
        total_games_with_full_audio,
        
        -- Flags importantes para análise
        CASE WHEN LOWER(language_name) IN ('english', 'american english') THEN TRUE ELSE FALSE END as has_english_audio,
        CASE WHEN LOWER(language_name) LIKE '%spanish%' THEN TRUE ELSE FALSE END as has_spanish_audio,
        CASE WHEN LOWER(language_name) LIKE '%french%' THEN TRUE ELSE FALSE END as has_french_audio,
        CASE WHEN LOWER(language_name) LIKE '%german%' THEN TRUE ELSE FALSE END as has_german_audio,
        CASE WHEN LOWER(language_name) LIKE '%chinese%' THEN TRUE ELSE FALSE END as has_chinese_audio,
        CASE WHEN LOWER(language_name) LIKE '%japanese%' THEN TRUE ELSE FALSE END as has_japanese_audio,
        CASE WHEN LOWER(language_name) LIKE '%russian%' THEN TRUE ELSE FALSE END as has_russian_audio,
        CASE WHEN LOWER(language_name) LIKE '%portuguese%' OR LOWER(language_name) LIKE '%brazil%' THEN TRUE ELSE FALSE END as has_portuguese_audio,
        
        language_family,
        market_tier,
        
        -- Flags de qualidade
        CASE 
            WHEN language_name IS NULL OR TRIM(language_name) = '' THEN TRUE
            ELSE FALSE
        END as has_invalid_language,
        
        -- Informações básicas do jogo para contexto
        game_name,
        release_date,
        current_price,
        is_free,
        estimated_owners_min,
        estimated_owners_max,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM language_rankings
)

SELECT * FROM final_output
