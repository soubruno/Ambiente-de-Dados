-- Staging model para relacionamento entre jogos e tags

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        gt.game_id,
        gt.tag_id,
        gt.votes,
        t.name as tag_name,
        g.name as game_name,
        g.release_date,
        g.current_price,
        g.is_free,
        g.positive_reviews,
        g.negative_reviews
    FROM steam_source.game_tags gt
    JOIN steam_source.tags t ON gt.tag_id = t.id
    JOIN steam_source.games g ON gt.game_id = g.app_id
    WHERE gt.game_id IS NOT NULL 
      AND gt.tag_id IS NOT NULL
      AND t.name IS NOT NULL 
      AND TRIM(t.name) != ''
      AND g.name IS NOT NULL
      AND gt.votes IS NOT NULL 
      AND gt.votes >= 0
),

tag_categorization AS (
    -- Categorização das tags e análises baseadas em votos
    SELECT 
        *,
        -- Análise dos votos
        CASE 
            WHEN votes >= 1000 THEN 'Very High'
            WHEN votes >= 500 THEN 'High'
            WHEN votes >= 100 THEN 'Medium'
            WHEN votes >= 10 THEN 'Low'
            ELSE 'Very Low'
        END as vote_tier,
        
        -- Categorização da tag
        CASE 
            WHEN LOWER(tag_name) IN ('action', 'adventure', 'rpg', 'strategy', 'simulation', 'sports', 'racing', 'fps', 'platformer') THEN 'Genre'
            WHEN LOWER(tag_name) IN ('singleplayer', 'multiplayer', 'co-op', 'online', 'local multiplayer', 'pvp', 'pve') THEN 'Gameplay Mode'
            WHEN LOWER(tag_name) IN ('indie', 'casual', 'hardcore', 'family friendly', 'mature', 'violent') THEN 'Audience'
            WHEN LOWER(tag_name) IN ('2d', '3d', 'pixel graphics', 'anime', 'cartoon', 'realistic', 'stylized') THEN 'Visual Style'
            WHEN LOWER(tag_name) IN ('story rich', 'choices matter', 'multiple endings', 'character customization', 'open world') THEN 'Story/World'
            WHEN LOWER(tag_name) IN ('early access', 'free to play', 'dlc', 'season pass', 'microtransactions') THEN 'Business Model'
            ELSE 'Other'
        END as tag_category,
        
        -- Força normalizada (0-1) baseada em votos
        CASE 
            WHEN votes > 0 THEN 
                LEAST(votes::DECIMAL / 1000.0, 1.0)  -- Normaliza até 1000 votos = força 1.0
            ELSE 0.1
        END as normalized_vote_strength
    FROM source_data
),

tag_rankings AS (
    -- Cálculos de rankings, posições e contagens
    SELECT
        *,
        -- Ranking da tag dentro do jogo
        ROW_NUMBER() OVER (
            PARTITION BY game_id 
            ORDER BY votes DESC NULLS LAST
        ) as tag_rank_in_game,
        
        -- Percentil da tag dentro do jogo
        PERCENT_RANK() OVER (
            PARTITION BY game_id 
            ORDER BY votes ASC NULLS FIRST
        ) as tag_percentile_in_game,
        
        -- Contagem de tags para o jogo
        COUNT(*) OVER (PARTITION BY game_id) as total_tags_for_game,
        
        -- Contagem de jogos para a tag
        COUNT(*) OVER (PARTITION BY tag_id) as total_games_for_tag
    FROM tag_categorization
),

final_output AS (
    -- Finalizando com as flags e ajustes adicionais
    SELECT
        game_id,
        tag_id,
        votes as tag_votes,
        tag_name,
        vote_tier,
        tag_rank_in_game,
        tag_percentile_in_game,
        
        -- Top N flags
        CASE 
            WHEN tag_rank_in_game <= 5 THEN TRUE
            ELSE FALSE
        END as is_top_5_tag,
        
        CASE 
            WHEN tag_rank_in_game <= 10 THEN TRUE
            ELSE FALSE
        END as is_top_10_tag,
        
        total_tags_for_game,
        total_games_for_tag,
        normalized_vote_strength,
        
        -- Flags de qualidade
        CASE 
            WHEN tag_name IS NULL OR TRIM(tag_name) = '' THEN TRUE
            ELSE FALSE
        END as has_invalid_tag,
        
        CASE 
            WHEN votes IS NULL OR votes < 0 THEN TRUE
            ELSE FALSE
        END as has_invalid_votes,
        
        tag_category,
        
        -- Informações básicas do jogo para contexto
        game_name,
        release_date,
        current_price,
        is_free,
        positive_reviews,
        negative_reviews,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM tag_rankings
)

SELECT * FROM final_output
