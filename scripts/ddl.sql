-- Conecta ao banco postgres
\c postgres;

-- Encerra todas as conexões com o banco steam_games 
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'steam_games' 
AND pid <> pg_backend_pid();

-- Dropa o banco 
DROP DATABASE IF EXISTS steam_games;

-- Cria o banco
CREATE DATABASE steam_games;

-- Conecta com o banco
\c steam_games;

-- TABELAS PRINCIPAIS

CREATE TABLE categories (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE developers (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE publishers (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE genres (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE tags (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE languages (
    id INT PRIMARY KEY,
    name VARCHAR(255)
);

CREATE TABLE games (
    app_id INT PRIMARY KEY,
    name VARCHAR(255),
    release_date DATE,
    estimated_owners_min INT,
    estimated_owners_max INT,
    current_price DECIMAL(10,2),
    currency_id INT,
    peak_ccu INT,
    required_age INT,
    dlc_count INT,
    about TEXT,
    short_description TEXT,
    header_image_url TEXT,
    website_url TEXT,
    support_url TEXT,
    metacritic_score INT,
    metacritic_url TEXT,
    user_score FLOAT,
    positive_reviews INT,
    negative_reviews INT,
    achievements_count INT,
    recommendations INT,
    average_playtime_forever INT,
    average_playtime_two_weeks INT,
    median_playtime_forever INT,
    median_playtime_two_weeks INT,
    game_status VARCHAR(50),
    is_free BOOLEAN,
    controller_support VARCHAR(50)
);

CREATE TABLE media (
    game_id INT,
    media_type VARCHAR(50),
    url TEXT,
    is_primary BOOLEAN,
    order_index INT,
    FOREIGN KEY (game_id) REFERENCES games(app_id)
);

-- RELACIONAMENTOS

CREATE TABLE game_developers (
    game_id INT,
    developer_id INT,
    PRIMARY KEY (game_id, developer_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (developer_id) REFERENCES developers(id)
);

CREATE TABLE game_publishers (
    game_id INT,
    publisher_id INT,
    PRIMARY KEY (game_id, publisher_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (publisher_id) REFERENCES publishers(id)
);

CREATE TABLE game_genres (
    game_id INT,
    genre_id INT,
    is_primary BOOLEAN,
    PRIMARY KEY (game_id, genre_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (genre_id) REFERENCES genres(id)
);

CREATE TABLE game_tags (
    game_id INT,
    tag_id INT,
    votes INT,
    PRIMARY KEY (game_id, tag_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (tag_id) REFERENCES tags(id)
);

CREATE TABLE game_categories (
    game_id INT,
    category_id INT,
    PRIMARY KEY (game_id, category_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE game_full_audio_languages (
    game_id INT,
    language_id INT,
    PRIMARY KEY (game_id, language_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (language_id) REFERENCES languages(id)
);

CREATE TABLE game_supported_languages (
    game_id INT,
    language_id INT,
    interface_support BOOLEAN,
    subtitles_support BOOLEAN,
    PRIMARY KEY (game_id, language_id),
    FOREIGN KEY (game_id) REFERENCES games(app_id),
    FOREIGN KEY (language_id) REFERENCES languages(id)
);


-- ÍNDICES PARA AS TABELAS PRINCIPAIS

-- Índices para busca por nome (muito comum em consultas)
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_developers_name ON developers(name);
CREATE INDEX idx_publishers_name ON publishers(name);
CREATE INDEX idx_genres_name ON genres(name);
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_languages_name ON languages(name);

-- ÍNDICES PARA AS TABELA GAMES

-- Busca por nome do jogo (consulta muito frequente)
CREATE INDEX idx_games_name ON games(name);

-- Busca por data de lançamento (consultas de intervalos de tempo)
CREATE INDEX idx_games_release_date ON games(release_date);

-- Busca por preço (ordenação e filtros por faixa de preço)
CREATE INDEX idx_games_current_price ON games(current_price);

-- Busca por faixa de proprietários estimados (análises de popularidade)
CREATE INDEX idx_games_estimated_owners ON games(estimated_owners_min, estimated_owners_max);

-- Busca por avaliações metacritic (filtros por qualidade)
CREATE INDEX idx_games_metacritic_score ON games(metacritic_score);

-- Busca por avaliações de usuários
CREATE INDEX idx_games_user_score ON games(user_score);

-- Busca por jogos gratuitos (filtro comum)
CREATE INDEX idx_games_is_free ON games(is_free);

-- Busca por status do jogo
CREATE INDEX idx_games_status ON games(game_status);

-- Busca por idade requerida (filtros parentais)
CREATE INDEX idx_games_required_age ON games(required_age);

-- Índice composto para análises de reviews
CREATE INDEX idx_games_reviews ON games(positive_reviews, negative_reviews);

-- Índice para tempo de jogo médio (análises de engajamento)
CREATE INDEX idx_games_playtime ON games(average_playtime_forever);

-- ÍNDICES PARA AS TABELAS DE RELACIONAMENTO

-- game_developers: busca jogos por desenvolvedor
CREATE INDEX idx_game_developers_developer ON game_developers(developer_id);

-- game_publishers: busca jogos por publisher
CREATE INDEX idx_game_publishers_publisher ON game_publishers(publisher_id);

-- game_genres: busca jogos por gênero e gêneros primários
CREATE INDEX idx_game_genres_genre ON game_genres(genre_id);
CREATE INDEX idx_game_genres_primary ON game_genres(is_primary);
CREATE INDEX idx_game_genres_genre_primary ON game_genres(genre_id, is_primary);

-- game_tags: busca jogos por tag e ordenação por votos
CREATE INDEX idx_game_tags_tag ON game_tags(tag_id);
CREATE INDEX idx_game_tags_votes ON game_tags(votes DESC);
CREATE INDEX idx_game_tags_tag_votes ON game_tags(tag_id, votes DESC);

-- game_categories: busca jogos por categoria
CREATE INDEX idx_game_categories_category ON game_categories(category_id);

-- game_full_audio_languages: busca jogos por idioma de áudio
CREATE INDEX idx_game_full_audio_lang ON game_full_audio_languages(language_id);

-- game_supported_languages: busca suporte específico de idioma
CREATE INDEX idx_game_supported_lang ON game_supported_languages(language_id);
CREATE INDEX idx_game_supported_interface ON game_supported_languages(interface_support);
CREATE INDEX idx_game_supported_subtitles ON game_supported_languages(subtitles_support);

-- media: busca mídia por tipo e ordenação
CREATE INDEX idx_media_type ON media(media_type);
CREATE INDEX idx_media_primary ON media(is_primary);
CREATE INDEX idx_media_order ON media(game_id, order_index);
CREATE INDEX idx_media_type_primary ON media(media_type, is_primary);


-- VIEWS CRIADAS PARA O BANCO

-- view_genres_triple_axis_analysis: 
-- Analisa e compara os gêneros dos jogos sob três eixos: 
-- 1. Volume (quantidade total de jogos no gênero)
-- 2. Popularidade (média de avaliações positivas)
-- 3. Engajamento (tempo médio de jogo)

CREATE OR REPLACE VIEW view_genres_triple_axis_analysis AS
SELECT 
    gnr.name AS genre_name,
    
    -- Quantidade total de jogos vinculados a este gênero
    COUNT(DISTINCT gm.app_id) AS total_games,

    -- Média de avaliações positivas dos jogos deste gênero
    ROUND(AVG(gm.positive_reviews), 2) AS avg_positive_reviews,

    -- Tempo médio de jogo (em minutos) para os jogos deste gênero
    ROUND(AVG(gm.average_playtime_forever), 2) AS avg_playtime_forever

FROM 
    genres gnr
JOIN 
    game_genres gg ON gnr.id = gg.genre_id
JOIN 
    games gm ON gm.app_id = gg.game_id

GROUP BY 
    gnr.name

ORDER BY 
    avg_positive_reviews DESC,  -- Gêneros mais populares primeiro
    avg_playtime_forever DESC;  -- Critério secundário: engajamento


-- view_trending_games_two_weeks: 
-- Calcula um "fator de tendência", indicando o quanto o jogo cresceu em engajamento recente.
-- Esta view identifica jogos em ascensão, comparando o tempo médio jogado
-- nas últimas duas semanas com o tempo médio jogado ao longo da vida útil do jogo.
-- Permite identificar jogos que estão se tornando populares agora, mesmo que não sejam grandes sucessos históricos.

CREATE OR REPLACE VIEW view_trending_games_two_weeks AS

SELECT
    g.app_id,
    g.name AS game_name,
    g.release_date,
    
    -- Tempo médio total jogado desde o lançamento (em minutos)
    g.average_playtime_forever,
    
    -- Tempo médio jogado nas últimas duas semanas (em minutos)
    g.average_playtime_two_weeks,
    
    -- Cálculo do fator de tendência: 
    -- quanto representa o tempo das duas semanas em relação ao histórico
    CASE 
        WHEN g.average_playtime_forever = 0 THEN NULL  -- evita divisão por zero
        ELSE ROUND((g.average_playtime_two_weeks::DECIMAL / g.average_playtime_forever) * 100, 2)
    END AS trend_factor_percent

FROM 
    games g

WHERE 
    -- Considera apenas jogos que tiveram ao menos algum tempo jogado recentemente
    g.average_playtime_two_weeks > 0 AND
    -- E que possuem histórico suficiente para comparação
    g.average_playtime_forever > 0

ORDER BY 
    trend_factor_percent DESC,           -- Os mais "em alta" primeiro
    g.average_playtime_two_weeks DESC;   -- Critério secundário: tempo recente absoluto


-- view_top_n_tags_per_genre: 
-- Esta view identifica as 3 tags mais associadas a cada gênero, com base na quantidade de vezes que uma tag aparece em jogos daquele gênero.
-- Permite visualizar as tags dominantes por gênero, ou seja, o que o público mais associa a cada tipo de jogo.
-- Serve como base para recomendações e categorização de jogos.

CREATE OR REPLACE VIEW view_top_n_tags_per_genre AS

WITH tag_counts_per_genre AS (
    SELECT 
        gnr.name AS genre_name,
        tg.name AS tag_name,
        COUNT(*) AS tag_occurrence,
        
        -- Gera numeração para cada tag dentro do seu respectivo gênero
        ROW_NUMBER() OVER (
            PARTITION BY gnr.name
            ORDER BY COUNT(*) DESC
        ) AS rank_within_genre

    FROM 
        game_genres gg
    JOIN 
        genres gnr ON gg.genre_id = gnr.id
    JOIN 
        games gm ON gg.game_id = gm.app_id
    JOIN 
        game_tags gt ON gm.app_id = gt.game_id
    JOIN 
        tags tg ON gt.tag_id = tg.id

    GROUP BY 
        gnr.name, tg.name
)

SELECT 
    genre_name,
    tag_name,
    tag_occurrence,
    rank_within_genre

FROM 
    tag_counts_per_genre

-- Apenas as 3 principais tags por gênero
WHERE 
    rank_within_genre <= 3

ORDER BY 
    genre_name,
    rank_within_genre;


-- FUNCTIONS CRIADAS PARA O BANCO

-- fn_classificar_categoria_por_engajamento():
-- A função classifica cada categoria de jogo com base no nível de engajamento médio dos usuários, 
-- medido pelo tempo médio de jogo (average_playtime_forever) dos jogos associados a ela.
-- Ela retorna uma classificação textual de engajamento por categoria base em percentis (33% e 66%):
-- Baixa: tempo abaixo do 33º percentil;
-- Média: entre os percentis 33% e 66%;
-- Alta: acima do 66º percentil.

CREATE OR REPLACE FUNCTION fn_classificar_categoria_por_engajamento()
RETURNS TABLE (
    categoria_id INT,
    categoria_nome TEXT,
    tempo_medio_jogado NUMERIC,
    classificacao_engajamento TEXT
) AS
$$
DECLARE
    p33 NUMERIC;
    p66 NUMERIC;
    rec RECORD;
BEGIN
    SELECT 
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY avg_playtime),
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY avg_playtime)
    INTO p33, p66
    FROM (
        SELECT 
            gc.category_id,
            AVG(g.average_playtime_forever) AS avg_playtime
        FROM 
            game_categories gc
        JOIN 
            games g ON g.app_id = gc.game_id
        GROUP BY 
            gc.category_id
    ) sub;

    -- Loop por categoria e calcular classificação
    FOR rec IN
        SELECT 
            c.id AS categoria_id,
            c.name AS categoria_nome,
            AVG(g.average_playtime_forever) AS tempo_medio_jogado
        FROM 
            game_categories gc
        JOIN 
            games g ON g.app_id = gc.game_id
        JOIN 
            categories c ON c.id = gc.category_id
        GROUP BY 
            c.id, c.name
    LOOP
        classificacao_engajamento := CASE 
            WHEN rec.tempo_medio_jogado < p33 THEN 'Baixa'
            WHEN rec.tempo_medio_jogado < p66 THEN 'Média'
            ELSE 'Alta'
        END;

        categoria_id := rec.categoria_id;
        categoria_nome := rec.categoria_nome;
        tempo_medio_jogado := rec.tempo_medio_jogado;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- fn_classificar_genero_por_engajamento():
-- A função tem como objetivo classificar cada gênero de jogo com base no nível de engajamento dos jogadores, 
-- utilizando como métrica o tempo médio de jogo (average_playtime_forever) associado aos jogos daquele gênero.
-- Ela divide os gêneros em três categorias:
-- Baixa: engajamento abaixo do 33º percentil;
-- Média: entre os percentis 33% e 66%;
-- Alta: acima do 66º percentil.

CREATE OR REPLACE FUNCTION fn_classificar_genero_por_engajamento()
RETURNS TABLE (
    genero_id INT,
    genero_nome TEXT,
    tempo_medio_jogado NUMERIC,
    classificacao_engajamento TEXT
) AS
$$
DECLARE
    p33 NUMERIC;
    p66 NUMERIC;
    rec RECORD;
BEGIN
    SELECT 
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY avg_playtime),
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY avg_playtime)
    INTO p33, p66
    FROM (
        SELECT 
            gg.genre_id,
            AVG(g.average_playtime_forever) AS avg_playtime
        FROM 
            game_genres gg
        JOIN 
            games g ON g.app_id = gg.game_id
        GROUP BY 
            gg.genre_id
    ) sub;

    -- Loop por gênero e calcular classificação
    FOR rec IN
        SELECT 
            gen.id AS genero_id,
            gen.name AS genero_nome,
            AVG(g.average_playtime_forever) AS tempo_medio_jogado
        FROM 
            game_genres gg
        JOIN 
            games g ON g.app_id = gg.game_id
        JOIN 
            genres gen ON gen.id = gg.genre_id
        GROUP BY 
            gen.id, gen.name
    LOOP
        classificacao_engajamento := CASE 
            WHEN rec.tempo_medio_jogado < p33 THEN 'Baixa'
            WHEN rec.tempo_medio_jogado < p66 THEN 'Média'
            ELSE 'Alta'
        END;

        genero_id := rec.genero_id;
        genero_nome := rec.genero_nome;
        tempo_medio_jogado := rec.tempo_medio_jogado;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- fn_obter_jogos_com_conquistas_relevantes():
-- A função retorna todos os jogos cujo número de conquistas (achievements_count) está acima da média geral da base de dados.
-- É voltada para destacar jogos com forte apelo para jogadores completistas, ou seja, aqueles que gostam de colecionar conquistas, 
-- troféus ou medalhas dentro dos jogos.
-- Boa para segmentações do tipo: “os mais desafiadores do gênero X”, ou “ranking por conquistas”.

CREATE OR REPLACE FUNCTION fn_obter_jogos_com_conquistas_relevantes()
RETURNS TABLE (
    game_id INT,
    game_name TEXT,
    achievements_count INT,
    user_score FLOAT
) AS
$$
DECLARE
    v_media_conquistas NUMERIC;
    rec RECORD;
BEGIN
    -- Calcula a média geral de conquistas entre os jogos
    SELECT AVG(g.achievements_count)
    INTO v_media_conquistas
    FROM games g
    WHERE g.achievements_count IS NOT NULL;

    -- Itera sobre os jogos com conquistas acima da média
    FOR rec IN
        SELECT 
            g.app_id,
            g.name,
            g.achievements_count,
            g.user_score
        FROM 
            games g
        WHERE 
            g.achievements_count IS NOT NULL
            AND g.achievements_count > v_media_conquistas
        ORDER BY 
            g.achievements_count DESC
    LOOP
        -- Atribui valores para o retorno da função
        game_id := rec.app_id;
        game_name := rec.name;
        achievements_count := rec.achievements_count;
        user_score := rec.user_score;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- fn_obter_jogo_mais_popular_por_categoria()
-- Essa função retorna, para cada categoria de jogo, o jogo mais popular 
-- com base no número mínimo estimado de proprietários (estimated_owners_min).
-- Útil para exibir "Top Jogos por Categoria" com base em popularidade real estimada.

CREATE OR REPLACE FUNCTION fn_obter_jogo_mais_popular_por_categoria()
RETURNS TABLE (
    category_id INT,
    category_name TEXT,
    game_id INT,
    game_name TEXT,
    estimated_owners_min INT,
    estimated_owners_max INT,
    recommendations INT
) AS
$$
DECLARE
    rec RECORD;
BEGIN
    /*
    Essa função busca, para cada categoria, o jogo mais popular baseado
    no número estimado mínimo de proprietários (estimated_owners_min).
    Caso haja empate, pode-se considerar o número de recomendações como critério secundário.
    */
    
    FOR rec IN
        SELECT 
            c.id AS category_id,
            c.name AS category_name,
            g.app_id AS game_id,
            g.name AS game_name,
            g.estimated_owners_min,
            g.estimated_owners_max,
            g.recommendations
        FROM 
            categories c
        JOIN LATERAL (
            SELECT 
                g_inner.app_id,
                g_inner.name,
                g_inner.estimated_owners_min,
                g_inner.estimated_owners_max,
                g_inner.recommendations
            FROM 
                game_categories gc
            JOIN games g_inner ON g_inner.app_id = gc.game_id
            WHERE 
                gc.category_id = c.id
                AND g_inner.estimated_owners_min IS NOT NULL
            ORDER BY 
                g_inner.estimated_owners_min DESC,
                g_inner.recommendations DESC NULLS LAST
            LIMIT 1
        ) AS g ON TRUE
        ORDER BY c.name
    LOOP
        -- Atribui valores para retorno da função
        category_id := rec.category_id;
        category_name := rec.category_name;
        game_id := rec.game_id;
        game_name := rec.game_name;
        estimated_owners_min := rec.estimated_owners_min;
        estimated_owners_max := rec.estimated_owners_max;
        recommendations := rec.recommendations;

        -- Retorna cada registro
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS CRIADAS PARA O BANCO

-- trg_validar_midia_principal_unica:
-- Trigger para garantir que não haja mais de uma mídia principal por jogo e tipo de mídia
-- Esta trigger é acionada antes de inserir ou atualizar uma mídia.
-- Ela verifica se já existe outra mídia marcada como principal para o mesmo jogo e tipo de mídia
-- e, se existir, bloqueia a operação com uma exceção.
-- Isso garante que cada jogo tenha no máximo uma mídia principal por tipo, evitando conflitos.

CREATE OR REPLACE FUNCTION fn_validar_midia_principal_unica()
RETURNS TRIGGER AS
$$
DECLARE
    existe_midia BOOLEAN;
BEGIN
    -- Verifica se já existe outra mídia marcada como principal para o mesmo game_id e media_type
    IF NEW.is_primary = TRUE THEN
        SELECT EXISTS (
            SELECT 1
            FROM media
            WHERE game_id = NEW.game_id
              AND media_type = NEW.media_type
              AND is_primary = TRUE
              -- Garante que não está comparando com a própria mídia em caso de UPDATE
              AND (NEW.order_index IS NULL OR order_index <> NEW.order_index)
        ) INTO existe_midia;

        -- Se já existe uma principal, bloqueia
        IF existe_midia THEN
            RAISE EXCEPTION 'Já existe uma mídia principal para o jogo % do tipo %', NEW.game_id, NEW.media_type;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_validar_midia_principal_unica
BEFORE INSERT OR UPDATE ON media
FOR EACH ROW
EXECUTE FUNCTION fn_validar_midia_principal_unica();

-- trg_ajustar_status_para_lancado:
-- Trigger para ajustar o status do jogo para 'lançado' automaticamente
-- Esta trigger é acionada após uma atualização na tabela games.
-- Ela verifica se a data de lançamento do jogo já passou e, se o status atual for 'aguardado',
-- atualiza o status para 'lançado'.
-- Isso garante que o status do jogo seja sempre coerente com a data de lançamento,
-- evitando inconsistências no banco de dados.

CREATE OR REPLACE FUNCTION fn_ajustar_status_para_lancado()
RETURNS TRIGGER AS
$$
BEGIN
    -- Verifica se a data de lançamento já passou e o status está como 'aguardado'
    IF NEW.release_date <= CURRENT_DATE AND NEW.game_status = 'aguardado' THEN
        -- Atualiza o status para 'lançado'
        UPDATE games
        SET game_status = 'lançado'
        WHERE app_id = NEW.app_id;
    END IF;

    RETURN NULL; -- AFTER trigger que só executa ação colateral
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_ajustar_status_para_lancado
AFTER UPDATE ON games
FOR EACH ROW
EXECUTE FUNCTION fn_ajustar_status_para_lancado();

-- trg_remover_associacoes_orfas:
-- Trigger para remover associações órfãs após a exclusão de um jogo
-- Esta trigger é acionada após a exclusão de um jogo na tabela games.
-- Ela remove todas as associações órfãs relacionadas a esse jogo, como mídias,
-- categorias, gêneros, desenvolvedores, publicadores, tags e idiomas.
-- Isso garante que não haja dados órfãos no banco de dados, mantendo a integridade referencial.

CREATE OR REPLACE FUNCTION fn_remover_associacoes_orfas()
RETURNS TRIGGER AS
$$
BEGIN
    -- Remove as mídias relacionadas
    DELETE FROM media WHERE game_id = OLD.app_id;

    -- Remove relacionamentos com categorias, gêneros, desenvolvedores, publicadores, tags, idiomas etc.
    DELETE FROM game_categories WHERE game_id = OLD.app_id;
    DELETE FROM game_genres WHERE game_id = OLD.app_id;
    DELETE FROM game_tags WHERE game_id = OLD.app_id;
    DELETE FROM game_developers WHERE game_id = OLD.app_id;
    DELETE FROM game_publishers WHERE game_id = OLD.app_id;
    DELETE FROM game_full_audio_languages WHERE game_id = OLD.app_id;
    DELETE FROM game_supported_languages WHERE game_id = OLD.app_id;

    RETURN NULL; -- AFTER trigger
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_remover_associacoes_orfas
AFTER DELETE ON games
FOR EACH ROW
EXECUTE FUNCTION fn_remover_associacoes_orfas();

-- PROCEDURES CRIADAS PARA O BANCO

-- pr_rever_classificacao_etaria_por_tags():
-- Esta procedure percorre todos os jogos que possuem tags sensíveis e ajusta
-- a classificação etária mínima (required_age) de acordo com o conteúdo.
-- A lógica abaixo usa os seguintes critérios:
-- - "Nudity", "Sexual Content"     => 18 anos
-- - "Violence", "Gore"             => mínimo 16 anos

CREATE OR REPLACE PROCEDURE pr_rever_classificacao_etaria_por_tags()
LANGUAGE plpgsql
AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT 
            g.app_id,
            MAX(
                CASE 
                    WHEN t.name IN ('Nudity', 'Sexual Content') THEN 18
                    WHEN t.name IN ('Violence', 'Gore') THEN 16
                    ELSE g.required_age
                END
            ) AS nova_idade
        FROM 
            games g
        JOIN 
            game_tags gt ON gt.game_id = g.app_id
        JOIN 
            tags t ON t.id = gt.tag_id
        GROUP BY 
            g.app_id
    LOOP
        -- Atualiza somente se a nova idade for maior que a atual
        UPDATE games
        SET required_age = rec.nova_idade
        WHERE app_id = rec.app_id
          AND required_age IS DISTINCT FROM rec.nova_idade;

        RAISE NOTICE 'Atualizado jogo % para idade mínima de % anos.', rec.app_id, rec.nova_idade;
    END LOOP;
END;
$$;

-- pr_corrigir_associacoes_com_linguas_invalidas():
-- Esta procedure remove associações inválidas na tabela game_supported_languages,
-- ou seja, aquelas que referenciam um language_id que não existe na tabela languages.
-- Ela garante que todas as associações de idiomas estejam corretas e consistentes,
-- evitando problemas de integridade referencial.

CREATE OR REPLACE PROCEDURE pr_corrigir_associacoes_com_linguas_invalidas()
LANGUAGE plpgsql
AS $$
DECLARE
    linhas_afetadas INT;
BEGIN
    DELETE FROM game_supported_languages gsl
    WHERE NOT EXISTS (
        SELECT 1
        FROM languages l
        WHERE l.id = gsl.language_id
    )
    RETURNING *;

    GET DIAGNOSTICS linhas_afetadas = ROW_COUNT;
    RAISE NOTICE 'Linhas removidas com language_id inválido: %', linhas_afetadas;
END;
$$;

-- pr_normalizar_urls_quebradas():
-- Esta procedure percorre todos os jogos e normaliza as URLs quebradas.
-- Ela verifica se as URLs de website, suporte e imagem de cabeçalho estão no formato correto.
-- Isso garante que as URLs estejam sempre acessíveis e no formato adequado.
-- Se a URL não começa com "http://" ou "https://", ela é corrigida para incluir "https://".
-- A procedure atualiza as URLs somente quando houver alguma mudança detectada,
-- evitando atualizações desnecessárias no banco de dados.

CREATE OR REPLACE PROCEDURE pr_normalizar_urls_quebradas()
LANGUAGE plpgsql
AS $$
DECLARE
    jogo RECORD;
    nova_website TEXT;
    nova_support TEXT;
    nova_header TEXT;
BEGIN
    FOR jogo IN SELECT app_id, website_url, support_url, header_image_url FROM games LOOP
        -- Normalizar website_url
        nova_website := CASE 
            WHEN website_url IS NOT NULL AND website_url ~* '^(www\.)' THEN 'https://' || website_url
            WHEN website_url IS NOT NULL AND website_url !~* '^https?://' THEN 'https://' || website_url
            ELSE website_url
        END;

        -- Normalizar support_url
        nova_support := CASE 
            WHEN support_url IS NOT NULL AND support_url ~* '^(www\.)' THEN 'https://' || support_url
            WHEN support_url IS NOT NULL AND support_url !~* '^https?://' THEN 'https://' || support_url
            ELSE support_url
        END;

        -- Normalizar header_image_url
        nova_header := CASE 
            WHEN header_image_url IS NOT NULL AND header_image_url ~* '^(www\.)' THEN 'https://' || header_image_url
            WHEN header_image_url IS NOT NULL AND header_image_url !~* '^https?://' THEN 'https://' || header_image_url
            ELSE header_image_url
        END;

        -- Atualiza quando alguma mudança é detectada
        IF nova_website IS DISTINCT FROM jogo.website_url 
           OR nova_support IS DISTINCT FROM jogo.support_url 
           OR nova_header IS DISTINCT FROM jogo.header_image_url THEN

            UPDATE games
            SET 
                website_url = nova_website,
                support_url = nova_support,
                header_image_url = nova_header
            WHERE app_id = jogo.app_id;

        END IF;
    END LOOP;

    RAISE NOTICE 'URLs corrigidas.';
END;
$$;
