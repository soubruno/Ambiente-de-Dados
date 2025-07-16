-- Staging model para relacionamento entre jogos e desenvolvedores

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gd.game_id,
        gd.developer_id,
        d.name as developer_name,
        g.name as game_name,
        g.release_date,
        g.current_price,
        g.is_free
    FROM steam_source.game_developers gd
    JOIN steam_source.developers d ON gd.developer_id = d.id
    JOIN steam_source.games g ON gd.game_id = g.app_id
    WHERE gd.game_id IS NOT NULL 
      AND gd.developer_id IS NOT NULL
      AND d.name IS NOT NULL 
      AND TRIM(d.name) != ''
      AND g.name IS NOT NULL
),

developer_rankings AS (
    -- Cálculos de rankings, posições e contagens
    SELECT
        *,
        -- Ordem/prioridade do desenvolvedor para o jogo
        ROW_NUMBER() OVER (
            PARTITION BY game_id 
            ORDER BY developer_id
        ) as developer_order,
        
        -- Contagem de desenvolvedores para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_developers_for_game,
        
        -- Contagem de jogos para o desenvolvedor
        COUNT(*) OVER (PARTITION BY developer_id) as total_games_for_developer
    FROM source_data
),

final_output AS (
    -- Finalizando com flags e ajustes adicionais
    SELECT
        game_id,
        developer_id,
        developer_name,
        developer_order,
        
        -- Flag se é o desenvolvedor principal (primeiro listado)
        CASE 
            WHEN developer_order = 1 THEN TRUE
            ELSE FALSE
        END as is_primary_developer,
        
        total_developers_for_game,
        total_games_for_developer,
        
        -- Flags de qualidade
        CASE 
            WHEN developer_name IS NULL OR TRIM(developer_name) = '' THEN TRUE
            ELSE FALSE
        END as has_invalid_developer,
        
        -- Informações básicas do jogo para contexto
        game_name,
        release_date,
        current_price,
        is_free,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM developer_rankings
)

SELECT * FROM final_output
