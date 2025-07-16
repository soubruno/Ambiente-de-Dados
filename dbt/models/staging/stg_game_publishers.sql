-- Staging model para relacionamento entre jogos e publicadores

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gp.game_id,
        gp.publisher_id,
        p.name as publisher_name,
        g.name as game_name,
        g.release_date,
        g.current_price,
        g.is_free,
        g.estimated_owners_min,
        g.estimated_owners_max
    FROM steam_source.game_publishers gp
    JOIN steam_source.publishers p ON gp.publisher_id = p.id
    JOIN steam_source.games g ON gp.game_id = g.app_id
    WHERE gp.game_id IS NOT NULL 
      AND gp.publisher_id IS NOT NULL
      AND p.name IS NOT NULL 
      AND TRIM(p.name) != ''
      AND g.name IS NOT NULL
),

publisher_rankings AS (
    -- Cálculos de rankings, posições e contagens
    SELECT
        *,
        -- Ordem/prioridade do publicador para o jogo
        ROW_NUMBER() OVER (
            PARTITION BY game_id 
            ORDER BY publisher_id
        ) as publisher_order,
        
        -- Contagem de publicadores para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_publishers_for_game,
        
        -- Contagem de jogos para o publicador
        COUNT(*) OVER (PARTITION BY publisher_id) as total_games_for_publisher
    FROM source_data
),

self_publishing_analysis AS (
    -- Análise de self-publishing (desenvolvedor = publicador)
    SELECT
        pr.*,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM steam_source.game_developers gd
                JOIN steam_source.developers d ON gd.developer_id = d.id
                WHERE gd.game_id = pr.game_id 
                AND TRIM(LOWER(d.name)) = TRIM(LOWER(pr.publisher_name))
            ) THEN TRUE
            ELSE FALSE
        END as is_self_published
    FROM publisher_rankings pr
),

final_output AS (
    -- Finalizando com flags e ajustes adicionais
    SELECT
        game_id,
        publisher_id,
        publisher_name,
        publisher_order,
        
        -- Flag se é o publicador principal (primeiro listado)
        CASE 
            WHEN publisher_order = 1 THEN TRUE
            ELSE FALSE
        END as is_primary_publisher,
        
        total_publishers_for_game,
        total_games_for_publisher,
        
        -- Flags de qualidade
        CASE 
            WHEN publisher_name IS NULL OR TRIM(publisher_name) = '' THEN TRUE
            ELSE FALSE
        END as has_invalid_publisher,
        
        is_self_published,
        
        -- Informações básicas do jogo para contexto
        game_name,
        release_date,
        current_price,
        is_free,
        estimated_owners_min,
        estimated_owners_max,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM self_publishing_analysis
)

SELECT * FROM final_output
