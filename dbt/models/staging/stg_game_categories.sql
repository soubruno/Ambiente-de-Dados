-- Staging model para relacionamento entre jogos e categorias

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gc.game_id,
        gc.category_id,
        c.name as category_name,
        g.name as game_name,
        g.release_date,
        g.current_price,
        g.is_free,
        g.required_age
    FROM steam_source.game_categories gc
    JOIN steam_source.categories c ON gc.category_id = c.id
    JOIN steam_source.games g ON gc.game_id = g.app_id
    WHERE gc.game_id IS NOT NULL 
      AND gc.category_id IS NOT NULL
      AND c.name IS NOT NULL 
      AND TRIM(c.name) != ''
      AND g.name IS NOT NULL
),

category_classification AS (
    -- Classificação e categorização das categorias
    SELECT 
        *,
        -- Categoria da categoria para análise
        CASE 
            WHEN LOWER(category_name) IN ('single-player', 'multi-player', 'co-op', 'online co-op', 'local co-op') THEN 'Player Mode'
            WHEN LOWER(category_name) IN ('steam achievements', 'steam trading cards', 'steam workshop', 'steam cloud') THEN 'Steam Features'
            WHEN LOWER(category_name) IN ('partial controller support', 'full controller support', 'vr supported') THEN 'Input/Hardware'
            WHEN LOWER(category_name) IN ('downloadable content', 'includes level editor', 'mod support') THEN 'Content Features'
            WHEN LOWER(category_name) IN ('captions available', 'commentary available') THEN 'Accessibility'
            ELSE 'Other'
        END as category_type,
        
        -- Importância da categoria (baseada em popularidade estimada)
        CASE 
            WHEN LOWER(category_name) IN ('single-player', 'multi-player') THEN 'High'
            WHEN LOWER(category_name) IN ('steam achievements', 'partial controller support', 'full controller support') THEN 'Medium'
            ELSE 'Low'
        END as category_importance
    FROM source_data
),

category_rankings AS (
    -- Cálculos de rankings, posições e contagens
    SELECT
        *,
        -- Ordem/prioridade da categoria para o jogo
        ROW_NUMBER() OVER (
            PARTITION BY game_id 
            ORDER BY category_id
        ) as category_order,
        
        -- Contagem de categorias para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_categories_for_game,
        
        -- Contagem de jogos para a categoria
        COUNT(*) OVER (PARTITION BY category_id) as total_games_for_category
    FROM category_classification
),

final_output AS (
    -- Finalizando com flags e ajustes adicionais
    SELECT
        game_id,
        category_id,
        category_name,
        category_order,
        total_categories_for_game,
        total_games_for_category,
        
        -- Flags de qualidade
        CASE 
            WHEN category_name IS NULL OR TRIM(category_name) = '' THEN TRUE
            ELSE FALSE
        END as has_invalid_category,
        
        category_type,
        category_importance,
        
        -- Flags específicas importantes para análise
        CASE WHEN LOWER(category_name) = 'single-player' THEN TRUE ELSE FALSE END as is_single_player,
        CASE WHEN LOWER(category_name) LIKE '%multi-player%' THEN TRUE ELSE FALSE END as is_multiplayer,
        CASE WHEN LOWER(category_name) LIKE '%co-op%' THEN TRUE ELSE FALSE END as is_coop,
        CASE WHEN LOWER(category_name) LIKE '%controller%' THEN TRUE ELSE FALSE END as has_controller_support,
        CASE WHEN LOWER(category_name) LIKE '%vr%' THEN TRUE ELSE FALSE END as is_vr_supported,
        CASE WHEN LOWER(category_name) LIKE '%steam%' THEN TRUE ELSE FALSE END as has_steam_features,
        
        -- Informações básicas do jogo para contexto
        game_name,
        release_date,
        current_price,
        is_free,
        required_age,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM category_rankings
)

SELECT * FROM final_output
