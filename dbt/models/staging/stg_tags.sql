-- Staging model para tags dos jogos

WITH tags_base AS (
    SELECT 
        t.id as tag_id,
        TRIM(t.name) as tag_name,
        TRIM(LOWER(t.name)) as tag_name_clean
    FROM steam_source.tags t
    WHERE t.name IS NOT NULL 
      AND TRIM(t.name) != ''
),

tags_with_games AS (
    SELECT 
        tb.*,
        
        -- Contagem de jogos por tag
        COUNT(gt.game_id) as total_games,
        
        -- Estatísticas de votos (usando game_tags se disponível)
        AVG(COALESCE(gt.votes, 1)) as avg_votes_per_game,
        SUM(COALESCE(gt.votes, 0)) as total_votes,
        
        -- Estatísticas de qualidade dos jogos
        AVG(g.metacritic_score) as avg_game_quality,
        AVG(g.current_price) as avg_game_price,
        
        -- Contagem para análise de tendência
        COUNT(CASE WHEN g.release_date >= CURRENT_DATE - INTERVAL '1 year' THEN 1 END) as recent_games,
        COUNT(CASE WHEN g.current_price = 0 THEN 1 END) as free_games_count,
        COUNT(CASE WHEN g.current_price > 0 THEN 1 END) as paid_games_count
        
    FROM tags_base tb
    LEFT JOIN steam_source.game_tags gt ON tb.tag_id = gt.tag_id
    LEFT JOIN steam_source.games g ON gt.game_id = g.app_id
    GROUP BY tb.tag_id, tb.tag_name, tb.tag_name_clean
)

SELECT 
    tag_id,
    tag_name,
    tag_name_clean,
    
    -- Categorização de tags
    CASE 
        WHEN LOWER(tag_name) IN ('action', 'adventure', 'rpg', 'strategy', 'simulation', 'sports', 'racing', 'fps', 'platformer') THEN 'Genre'
        WHEN LOWER(tag_name) IN ('singleplayer', 'multiplayer', 'co-op', 'online', 'local multiplayer', 'pvp', 'pve') THEN 'Gameplay'
        WHEN LOWER(tag_name) IN ('indie', 'casual', 'hardcore', 'family friendly', 'mature', 'violent') THEN 'Theme'
        WHEN LOWER(tag_name) IN ('2d', '3d', 'pixel graphics', 'anime', 'cartoon', 'realistic', 'stylized') THEN 'Technical'
        WHEN LOWER(tag_name) IN ('story rich', 'choices matter', 'multiple endings', 'character customization', 'open world') THEN 'Social'
        ELSE 'Mood'
    END as tag_category,
    
    CASE 
        WHEN LOWER(tag_name) IN ('action', 'adventure', 'rpg', 'strategy') THEN 'Genre-like'
        WHEN LOWER(tag_name) LIKE '%atmospheric%' OR LOWER(tag_name) LIKE '%dark%' OR LOWER(tag_name) LIKE '%horror%' THEN 'Mood'
        WHEN LOWER(tag_name) LIKE '%multiplayer%' OR LOWER(tag_name) LIKE '%co-op%' THEN 'Feature'
        ELSE 'Descriptive'
    END as tag_type,
    
    -- Métricas calculadas
    total_games,
    ROUND(avg_votes_per_game::NUMERIC, 2) as avg_votes_per_game,
    total_votes,
    ROUND(avg_game_quality::NUMERIC, 2) as avg_game_quality,
    ROUND(avg_game_price::NUMERIC, 2) as avg_game_price,
    
    -- Análise de tendência
    CASE 
        WHEN total_games = 0 THEN 'Stable'
        WHEN (recent_games::DECIMAL / total_games) > 0.3 THEN 'Rising'
        WHEN (recent_games::DECIMAL / total_games) < 0.1 THEN 'Declining'
        ELSE 'Stable'
    END as popularity_trend,
    
    -- Score de nicho (quanto menor o total de jogos, mais nicho)
    CASE 
        WHEN total_games >= 1000 THEN 1.0
        WHEN total_games >= 500 THEN 2.0
        WHEN total_games >= 100 THEN 3.0
        WHEN total_games >= 50 THEN 4.0
        ELSE 5.0
    END as niche_score,
    
    -- Apelo comercial baseado em preço médio e popularidade
    CASE 
        WHEN avg_game_price > 30 AND total_games > 100 THEN 5.0
        WHEN avg_game_price > 20 AND total_games > 50 THEN 4.0
        WHEN avg_game_price > 10 AND total_games > 20 THEN 3.0
        WHEN total_games > 10 THEN 2.0
        ELSE 1.0
    END as commercial_appeal,
    
    -- Metadados
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at

FROM tags_with_games
WHERE total_games > 0  -- Filtrar tags sem jogos associados
