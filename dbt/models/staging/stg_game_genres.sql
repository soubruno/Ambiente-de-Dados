-- Staging model para relacionamento entre jogos e gêneros

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gg.game_id,
        gg.genre_id,
        gg.is_primary,
        g.name as genre_name,
        gm.name as game_name,
        gm.release_date,
        gm.current_price,
        gm.is_free,
        gm.metacritic_score,
        gm.user_score
    FROM steam_source.game_genres gg
    JOIN steam_source.genres g ON gg.genre_id = g.id
    JOIN steam_source.games gm ON gg.game_id = gm.app_id
    WHERE gg.game_id IS NOT NULL 
      AND gg.genre_id IS NOT NULL
      AND g.name IS NOT NULL 
      AND TRIM(g.name) != ''
      AND gm.name IS NOT NULL
),

genre_categorization AS (
    -- Categorização dos gêneros
    SELECT 
        *,
        -- Categoria do gênero para análise
        CASE 
            WHEN LOWER(genre_name) IN ('action', 'adventure', 'rpg', 'strategy', 'simulation', 'sports', 'racing') THEN 'Core Genre'
            WHEN LOWER(genre_name) IN ('indie', 'casual', 'free to play', 'early access') THEN 'Publishing Model'
            WHEN LOWER(genre_name) IN ('massively multiplayer', 'multiplayer', 'co-op') THEN 'Social'
            ELSE 'Other'
        END as genre_category
    FROM source_data
),

genre_rankings AS (
    -- Cálculos de rankings, contagens e análises
    SELECT
        *,
        -- Ordem/prioridade do gênero para o jogo
        ROW_NUMBER() OVER (
            PARTITION BY game_id 
            ORDER BY 
                CASE WHEN is_primary THEN 0 ELSE 1 END,  -- Primários primeiro
                genre_id
        ) as genre_order,
        
        -- Contagem de gêneros para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_genres_for_game,
        
        -- Contagem de jogos para o gênero
        COUNT(*) OVER (PARTITION BY genre_id) as total_games_for_genre,
        
        -- Contagem de gêneros primários para o jogo
        SUM(CASE WHEN is_primary THEN 1 ELSE 0 END) OVER (
            PARTITION BY game_id
        ) as primary_genres_count
    FROM genre_categorization
),

final_output AS (
    -- Finalizando com as flags e ajustes adicionais
    SELECT
        game_id,
        genre_id,
        is_primary,
        genre_name,
        genre_order,
        total_genres_for_game,
        total_games_for_genre,
        primary_genres_count,
        
        -- Flags de qualidade
        CASE 
            WHEN genre_name IS NULL OR TRIM(genre_name) = '' THEN TRUE
            ELSE FALSE
        END as has_invalid_genre,
        
        CASE 
            WHEN is_primary IS NULL THEN TRUE
            ELSE FALSE
        END as has_missing_primary_flag,
        
        genre_category,
        
        -- Informações básicas do jogo para contexto
        game_name,
        release_date,
        current_price,
        is_free,
        metacritic_score,
        user_score,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM genre_rankings
)

SELECT * FROM final_output
