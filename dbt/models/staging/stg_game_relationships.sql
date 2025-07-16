-- Staging model para relacionamentos entre jogos e suas dimensões
WITH game_genre_relationships AS (
    SELECT 
        gg.game_id,
        gg.genre_id as related_id,
        gg.is_primary,
        g.name as related_name,
        'genre' as relationship_type
    FROM steam_source.game_genres gg
    JOIN steam_source.genres g ON gg.genre_id = g.id
),

game_category_relationships AS (
    SELECT 
        gc.game_id,
        gc.category_id as related_id,
        FALSE as is_primary,  -- Categorias não têm conceito de primária
        c.name as related_name,
        'category' as relationship_type
    FROM steam_source.game_categories gc
    JOIN steam_source.categories c ON gc.category_id = c.id
),

game_developer_relationships AS (
    SELECT 
        gd.game_id,
        gd.developer_id as related_id,
        -- Assume que o primeiro desenvolvedor é o principal (pode ser refinado)
        ROW_NUMBER() OVER (PARTITION BY gd.game_id ORDER BY gd.developer_id) = 1 as is_primary,
        d.name as related_name,
        'developer' as relationship_type
    FROM steam_source.game_developers gd
    JOIN steam_source.developers d ON gd.developer_id = d.id
),

game_publisher_relationships AS (
    SELECT 
        gp.game_id,
        gp.publisher_id as related_id,
        -- Assume que o primeiro publicador é o principal
        ROW_NUMBER() OVER (PARTITION BY gp.game_id ORDER BY gp.publisher_id) = 1 as is_primary,
        p.name as related_name,
        'publisher' as relationship_type
    FROM steam_source.game_publishers gp
    JOIN steam_source.publishers p ON gp.publisher_id = p.id
),

game_tag_relationships AS (
    SELECT 
        gt.game_id,
        gt.tag_id as related_id,
        FALSE as is_primary,  -- Tags não têm conceito de primária tradicional
        t.name as related_name,
        'tag' as relationship_type,
        gt.votes as tag_votes
    FROM steam_source.game_tags gt
    JOIN steam_source.tags t ON gt.tag_id = t.id
),

-- Unificar todos os relacionamentos
all_relationships AS (
    SELECT 
        game_id,
        related_id,
        is_primary,
        related_name,
        relationship_type,
        CAST(NULL AS integer) as tag_votes,
        1.0 as relationship_strength  -- Força padrão
    FROM game_genre_relationships
    
    UNION ALL
    
    SELECT 
        game_id,
        related_id,
        is_primary,
        related_name,
        relationship_type,
        CAST(NULL AS integer) as tag_votes,
        1.0 as relationship_strength
    FROM game_category_relationships
    
    UNION ALL
    
    SELECT 
        game_id,
        related_id,
        is_primary,
        related_name,
        relationship_type,
        CAST(NULL AS integer) as tag_votes,
        1.0 as relationship_strength
    FROM game_developer_relationships
    
    UNION ALL
    
    SELECT 
        game_id,
        related_id,
        is_primary,
        related_name,
        relationship_type,
        CAST(NULL AS integer) as tag_votes,
        1.0 as relationship_strength
    FROM game_publisher_relationships
    
    UNION ALL
    
    SELECT 
        game_id,
        related_id,
        is_primary,
        related_name,
        relationship_type,
        tag_votes,
        -- Força baseada em votos (normalizada 0-1)
        CASE 
            WHEN tag_votes > 0 THEN 
                LEAST(tag_votes::DECIMAL / 1000.0, 1.0)  -- Normaliza até 1000 votos = força 1.0
            ELSE 0.1
        END as relationship_strength
    FROM game_tag_relationships
)

SELECT 
    ar.game_id,
    ar.related_id,
    ar.relationship_type,
    ar.related_name,
    ar.is_primary,
    ar.tag_votes,
    ar.relationship_strength,
    
    -- Informações do jogo para contexto
    g.name as game_name,
    g.current_price,
    g.is_free,
    g.release_date,
    g.metacritic_score,
    g.user_score,
    g.positive_reviews,
    g.negative_reviews,
    
    -- Ranking da tag dentro do jogo (para tags)
    CASE 
        WHEN ar.relationship_type = 'tag' THEN
            ROW_NUMBER() OVER (
                PARTITION BY ar.game_id, ar.relationship_type 
                ORDER BY ar.tag_votes DESC NULLS LAST
            )
        ELSE NULL
    END as tag_rank_in_game,
    
    -- Força relativa do relacionamento dentro do tipo
    CASE 
        WHEN ar.relationship_type = 'tag' THEN
            PERCENT_RANK() OVER (
                PARTITION BY ar.game_id, ar.relationship_type 
                ORDER BY ar.tag_votes ASC NULLS FIRST
            )
        ELSE 1.0
    END as relative_strength_in_type,
    
    CURRENT_TIMESTAMP as loaded_at

FROM all_relationships ar
JOIN steam_source.games g ON ar.game_id = g.app_id
WHERE g.name IS NOT NULL
