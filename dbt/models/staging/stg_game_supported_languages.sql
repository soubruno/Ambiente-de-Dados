-- Staging model para idiomas suportados pelos jogos com detalhes de interface e legendas

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gsl.game_id,
        gsl.language_id,
        gsl.interface_support,
        gsl.subtitles_support,
        l.name as language_name,
        g.name as game_name,
        g.release_date,
        g.current_price,
        g.is_free,
        g.estimated_owners_min,
        g.estimated_owners_max
    FROM steam_source.game_supported_languages gsl
    JOIN steam_source.languages l ON gsl.language_id = l.id
    JOIN steam_source.games g ON gsl.game_id = g.app_id
    WHERE gsl.game_id IS NOT NULL 
      AND gsl.language_id IS NOT NULL
      AND l.name IS NOT NULL 
      AND TRIM(l.name) != ''
      AND g.name IS NOT NULL
),

support_analysis AS (
    -- Análise do nível de suporte para cada idioma
    SELECT 
        *,
        -- Análise do tipo de suporte
        CASE 
            WHEN interface_support = TRUE AND subtitles_support = TRUE THEN 'Full Support'
            WHEN interface_support = TRUE AND subtitles_support = FALSE THEN 'Interface Only'
            WHEN interface_support = FALSE AND subtitles_support = TRUE THEN 'Subtitles Only'
            ELSE 'Limited/Unknown'
        END as support_type,
        
        -- Score de suporte (para ranking)
        CASE 
            WHEN interface_support = TRUE AND subtitles_support = TRUE THEN 3
            WHEN interface_support = TRUE THEN 2
            WHEN subtitles_support = TRUE THEN 1
            ELSE 0
        END as support_score,
        
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
        END as market_tier
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
                -- Primeiro por score de suporte
                support_score ASC,
                -- Depois por idiomas mais comuns
                CASE 
                    WHEN LOWER(language_name) IN ('english', 'american english') THEN 1
                    WHEN LOWER(language_name) IN ('spanish', 'french', 'german') THEN 2
                    WHEN LOWER(language_name) IN ('chinese', 'japanese', 'russian') THEN 3
                    ELSE 4
                END,
                language_id
        ) as language_order,
        
        -- Contagem de idiomas suportados para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_supported_languages,
        
        -- Contagem de jogos para o idioma
        COUNT(*) OVER (PARTITION BY language_id) as total_games_supporting_language
    FROM support_analysis
),

final_output AS (
    -- Finalizando com flags e ajustes adicionais
    SELECT
        game_id,
        language_id,
        interface_support,
        subtitles_support,
        language_name,
        support_type,
        support_score,
        language_order,
        total_supported_languages,
        total_games_supporting_language,
        
        -- Flags importantes para análise
        CASE WHEN LOWER(language_name) IN ('english', 'american english') THEN TRUE ELSE FALSE END as is_english,
        CASE WHEN LOWER(language_name) LIKE '%spanish%' THEN TRUE ELSE FALSE END as is_spanish,
        CASE WHEN LOWER(language_name) LIKE '%french%' THEN TRUE ELSE FALSE END as is_french,
        CASE WHEN LOWER(language_name) LIKE '%german%' THEN TRUE ELSE FALSE END as is_german,
        CASE WHEN LOWER(language_name) LIKE '%chinese%' THEN TRUE ELSE FALSE END as is_chinese,
        CASE WHEN LOWER(language_name) LIKE '%japanese%' THEN TRUE ELSE FALSE END as is_japanese,
        CASE WHEN LOWER(language_name) LIKE '%russian%' THEN TRUE ELSE FALSE END as is_russian,
        CASE WHEN LOWER(language_name) LIKE '%portuguese%' OR LOWER(language_name) LIKE '%brazil%' THEN TRUE ELSE FALSE END as is_portuguese,
        
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
