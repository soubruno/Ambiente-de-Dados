-- DATA WAREHOUSE STEAM GAMES - MODELO ESTRELA

CREATE SCHEMA IF NOT EXISTS public_marts;
CREATE SCHEMA IF NOT EXISTS public_staging;
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS snapshots;

GRANT ALL ON SCHEMA public_marts TO dw_user;
GRANT ALL ON SCHEMA public_staging TO dw_user;
GRANT ALL ON SCHEMA raw TO dw_user;
GRANT ALL ON SCHEMA snapshots TO dw_user;

-- DIM_DATE: Dimensão de tempo para análises temporais
CREATE TABLE IF NOT EXISTS public_marts.dim_date (
    date_key INT PRIMARY KEY,                    -- YYYYMMDD
    full_date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    day INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    week_of_year INT NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE,
    season VARCHAR(20) NOT NULL,
    fiscal_year INT NOT NULL,
    fiscal_quarter INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_GAME: Dimensão principal
CREATE TABLE IF NOT EXISTS public_marts.dim_game (
    game_key SERIAL PRIMARY KEY,
    app_id INT NOT NULL,
    
    -- INFORMAÇÕES BÁSICAS (textos descritivos)
    name VARCHAR(500) NOT NULL,
    short_description TEXT,
    about TEXT,
    detailed_description TEXT,
    header_image_url TEXT,
    website_url TEXT,
    support_url TEXT,
    metacritic_url TEXT,
    
    -- CLASSIFICAÇÕES E CATEGORIAS DESCRITIVAS
    game_status VARCHAR(50),                     -- Released, Early Access, Upcoming
    controller_support VARCHAR(50),              -- Full, Partial, None
    content_rating VARCHAR(20),                  -- Everyone, Teen, Mature, Adults Only
    
    -- Categorização de preço (descritiva)
    price_category VARCHAR(20),                  -- Free, Budget, Economy, Standard, Premium, AAA, Luxury
    price_tier_description TEXT,                 -- Descrição do tier de preço
    monetization_model VARCHAR(50),              -- One-time, F2P, Subscription, Freemium
    
    -- Categorização de idade  
    age_category VARCHAR(20),                    -- Everyone, Teen, Mature, Adults Only
    age_justification TEXT,                      -- Por que tem essa classificação
    
    -- Categorização de DLC
    dlc_category VARCHAR(30),                    -- None, Few, Many, Extensive
    dlc_strategy VARCHAR(50),                    -- No DLC, Content Packs, Season Pass, Ongoing
    
    -- Categorização de conquistas
    achievement_category VARCHAR(30),            -- None, Basic, Rich, Achievement Hunter
    achievement_difficulty VARCHAR(30),          -- Easy, Medium, Hard, Completionist
    
    -- ANÁLISES DE MERCADO E POSICIONAMENTO
    -- Posicionamento no mercado
    market_position VARCHAR(30),                 -- Indie, Mid-tier, AAA, Premium
    target_audience VARCHAR(50),                 -- Casual, Core, Hardcore, Niche, Family, Professional
    audience_age_range VARCHAR(30),              -- Kids, Teens, Young Adults, Adults, All Ages
    
    -- Categorização de sucesso
    success_tier VARCHAR(20),                    -- Flop, Modest, Success, Hit, Blockbuster
    success_tier_description TEXT,               -- Descrição do nível de sucesso
    
    -- Categorização de popularidade
    popularity_tier VARCHAR(20),                 -- Niche, Popular, Hit, Blockbuster
    popularity_description TEXT,                 -- Descrição da popularidade
    
    -- Categorização de qualidade
    quality_tier VARCHAR(20),                    -- Poor, Average, Good, Excellent
    quality_analysis TEXT,                       -- Análise da qualidade
    
    -- CARACTERÍSTICAS TÉCNICAS E FUNCIONAIS

    -- Suporte técnico
    platform_focus VARCHAR(50),                 -- PC Only, Multi-platform, Console Port
    technical_requirements VARCHAR(30),          -- Low, Medium, High, Extreme
    performance_optimization VARCHAR(30),        -- Poor, Average, Good, Excellent
    
    -- Características de jogabilidade
    gameplay_style VARCHAR(100),                -- Single-player focused, Multiplayer, Both, Co-op
    game_length VARCHAR(30),                     -- Short, Medium, Long, Endless
    difficulty_level VARCHAR(30),               -- Easy, Medium, Hard, Variable
    learning_curve VARCHAR(30),                 -- Simple, Moderate, Steep, Expert
    
    -- Características sociais
    community_features VARCHAR(100),            -- None, Basic, Rich, Platform-dependent
    multiplayer_type VARCHAR(50),               -- None, Local, Online, Cross-platform
    social_integration VARCHAR(50),             -- None, Basic, Extensive, Platform-native
    
    -- ANÁLISES TEMPORAIS E CONTEXTUAIS
    
    -- Contexto temporal
    release_era VARCHAR(30),                     -- Retro, Classic, Modern, Recent, New
    development_period VARCHAR(30),             -- Quick, Standard, Extended, Long Development
    post_launch_support VARCHAR(30),            -- None, Basic, Active, Extensive
    
    -- Contexto de mercado na época do lançamento
    market_context_at_launch TEXT,              -- Contexto do mercado quando foi lançado
    competition_level_at_launch VARCHAR(30),    -- Low, Medium, High, Saturated
    innovation_level VARCHAR(30),               -- Conservative, Iterative, Innovative, Revolutionary
    
    -- ESTATÍSTICAS E NÚMEROS DE REFERÊNCIA

    required_age INT,
    dlc_count INT,
    achievements_count INT,
    
    -- Benchmarks de qualidade (para referência rápida)
    metacritic_benchmark VARCHAR(30),           -- Poor, Mixed, Good, Excellent
    user_review_benchmark VARCHAR(30),          -- Negative, Mixed, Positive, Very Positive
    
    -- INFORMAÇÕES DE LOCALIZAÇÃO E MERCADOS
    primary_markets TEXT,                       -- Mercados principais (JSON ou texto)
    localization_quality VARCHAR(30),           -- Poor, Basic, Good, Excellent
    cultural_adaptation VARCHAR(30),            -- None, Basic, Localized, Fully Adapted
    
    -- METADADOS E CONTROLE
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiration_date DATE DEFAULT '9999-12-31',
    is_current BOOLEAN DEFAULT TRUE,
    data_source VARCHAR(50) DEFAULT 'Steam API',
    data_quality_score DECIMAL(3,2) DEFAULT 1.0,
    last_verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- CONSTRAINTS
    UNIQUE(app_id, effective_date)
);

-- DIM_DEVELOPER: Dimensão de desenvolvedores com métricas agregadas
CREATE TABLE IF NOT EXISTS public_marts.dim_developer (
    developer_key SERIAL PRIMARY KEY,
    developer_id INT NOT NULL,                   -- Natural key
    name VARCHAR(255) NOT NULL,
    
    -- INFORMAÇÕES DESCRITIVAS
    company_description TEXT,
    headquarters_location VARCHAR(100),
    founding_year INT,
    company_size VARCHAR(30),                    -- Solo, Small, Medium, Large, Enterprise
    website_url VARCHAR(500),
    
    -- Especialização e foco
    primary_specialization VARCHAR(50),          -- Gênero/tipo em que se especializa
    secondary_specializations TEXT,              -- Outras especializações (lista)
    typical_platforms TEXT,                      -- Plataformas onde costuma desenvolver
    common_engines TEXT,                         -- Engines que costuma usar
    
    -- MÉTRICAS CALCULADAS DO DESENVOLVEDOR
    total_games INT DEFAULT 0,
    total_games_as_primary INT DEFAULT 0,        -- Como desenvolvedor principal
    total_games_as_secondary INT DEFAULT 0,      -- Como desenvolvedor secundário
    avg_metacritic_score DECIMAL(5,2),
    avg_user_score DECIMAL(5,2),
    total_positive_reviews BIGINT DEFAULT 0,
    total_negative_reviews BIGINT DEFAULT 0,
    avg_price DECIMAL(10,2),
    avg_playtime DECIMAL(10,2),
    
    -- ANÁLISES DE MERCADO E POSICIONAMENTO
    developer_tier VARCHAR(30),                  -- Indie, Mid-tier, AAA, Major
    market_presence VARCHAR(30),                 -- Emerging, Established, Dominant
    reputation_score DECIMAL(5,2),              -- Score baseado em reviews e qualidade
    innovation_level VARCHAR(30),               -- Conservative, Iterative, Innovative, Revolutionary
    
    -- Estratégias de negócio
    business_model VARCHAR(50),                  -- Traditional, F2P, Early Access, Publisher
    monetization_approach VARCHAR(50),           -- One-time, DLC-heavy, Microtransactions, Subscription
    release_frequency VARCHAR(30),               -- Infrequent, Regular, Prolific
    
    -- Relacionamentos típicos (sem bridge table)
    frequent_publishers TEXT,                    -- Publicadores com quem trabalha frequentemente
    typical_genres TEXT,                         -- Gêneros que mais desenvolve
    common_categories TEXT,                      -- Categorias mais comuns em seus jogos
    
    -- ANÁLISES DE SUCESSO E QUALIDADE
    success_rate_percent DECIMAL(5,2),          -- % de jogos bem-sucedidos
    hit_games_count INT DEFAULT 0,              -- Número de grandes sucessos
    avg_development_time_months INT,             -- Tempo médio de desenvolvimento
    post_launch_support_quality VARCHAR(30),    -- Poor, Basic, Good, Excellent
    
    years_active INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_PUBLISHER: Dimensão de publicadores com métricas agregadas
CREATE TABLE IF NOT EXISTS public_marts.dim_publisher (
    publisher_key SERIAL PRIMARY KEY,
    publisher_id INT NOT NULL,                   -- Natural key
    name VARCHAR(255) NOT NULL,
    
    -- INFORMAÇÕES DESCRITIVAS

    company_description TEXT,
    headquarters_location VARCHAR(100),
    founding_year INT,
    company_size VARCHAR(30),                    -- Small, Medium, Large, Major, Platform-owner
    website_url VARCHAR(500),
    
    -- Foco e especialização
    primary_focus VARCHAR(50),                   -- PC, Console, Mobile, Multi-platform
    target_markets TEXT,                         -- Mercados geográficos principais
    typical_price_ranges TEXT,                   -- Faixas de preço que costuma trabalhar
    common_genres TEXT,                          -- Gêneros que mais publica
    
    -- MÉTRICAS CALCULADAS DO PUBLICADOR
    total_games INT DEFAULT 0,
    total_games_as_primary INT DEFAULT 0,        -- Como publicador principal
    total_games_as_secondary INT DEFAULT 0,      -- Como publicador secundário/regional
    avg_metacritic_score DECIMAL(5,2),
    avg_user_score DECIMAL(5,2),
    total_positive_reviews BIGINT DEFAULT 0,
    total_negative_reviews BIGINT DEFAULT 0,
    avg_price DECIMAL(10,2),
    market_share DECIMAL(5,2),
    
    -- ANÁLISES DE MERCADO E POSICIONAMENTO
    publisher_tier VARCHAR(30),                 -- Independent, Mid-tier, Major, Platform-holder
    market_reach VARCHAR(30),                   -- Regional, National, Global
    business_model VARCHAR(50),                 -- Traditional, F2P, Platform, Subscription
    distribution_strategy VARCHAR(50),          -- Digital-only, Retail+Digital, Platform-exclusive
    reputation_score DECIMAL(5,2),
    
    -- Relacionamentos e parcerias
    frequent_developers TEXT,                    -- Desenvolvedores com quem trabalha frequentemente
    platform_relationships TEXT,                -- Relacionamentos especiais com plataformas
    regional_partners TEXT,                      -- Parceiros regionais/co-publicadores
    
    -- ESTRATÉGIAS E PERFORMANCE
    marketing_strength VARCHAR(30),             -- Weak, Moderate, Strong, Dominant
    global_reach_score DECIMAL(5,2),            -- Score de alcance global
    innovation_support VARCHAR(30),             -- Conservative, Moderate, Innovative, Pioneer
    indie_friendly_score DECIMAL(5,2),          -- Quão amigável é com desenvolvedores indie
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_GENRE: Dimensão de gêneros com análises de mercado
CREATE TABLE IF NOT EXISTS public_marts.dim_genre (
    genre_key SERIAL PRIMARY KEY,
    genre_id INT NOT NULL,                       -- Natural key
    name VARCHAR(255) NOT NULL,
    description TEXT,
    -- Métricas do gênero
    total_games INT DEFAULT 0,
    avg_price DECIMAL(10,2),
    avg_playtime DECIMAL(10,2),
    avg_metacritic_score DECIMAL(5,2),
    avg_user_score DECIMAL(5,2),
    total_estimated_owners BIGINT DEFAULT 0,
    -- Análises de mercado
    popularity_rank INT,
    market_share_percent DECIMAL(5,2),
    genre_maturity VARCHAR(30),                 -- Emerging, Growing, Mature, Declining
    monetization_potential VARCHAR(30),         -- Low, Medium, High, Premium
    competitive_level VARCHAR(30),              -- Low, Moderate, High, Saturated
    target_demographic VARCHAR(50),             -- Casual, Core, Hardcore, All Ages
    seasonal_pattern VARCHAR(30),               -- Stable, Holiday-driven, Summer-peak
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_CATEGORY: Dimensão de categorias com características
CREATE TABLE IF NOT EXISTS public_marts.dim_category (
    category_key SERIAL PRIMARY KEY,
    category_id INT NOT NULL,                    -- Natural key
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_type VARCHAR(50),                   -- Feature, Platform, Social, Technical
    total_games INT DEFAULT 0,
    avg_price_impact DECIMAL(5,2),              -- Como categoria afeta preço
    popularity_rank INT,
    user_preference_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_LANGUAGE: Dimensão de idiomas com análise de mercado
CREATE TABLE IF NOT EXISTS public_marts.dim_language (
    language_key SERIAL PRIMARY KEY,
    language_id INT NOT NULL,                    -- Natural key
    language_name VARCHAR(255) NOT NULL,
    language_name_clean VARCHAR(255),
    -- Classificação do idioma
    language_family VARCHAR(100),
    primary_region VARCHAR(100),
    estimated_speakers_millions INT,
    -- Métricas no gaming
    total_games_supported INT DEFAULT 0,
    avg_game_quality DECIMAL(5,2),
    avg_game_price DECIMAL(10,2),
    market_priority VARCHAR(30),                -- Primary, Secondary, Niche
    localization_investment VARCHAR(30),        -- High, Medium, Low, Minimal
    -- Flags de análise
    is_english BOOLEAN DEFAULT FALSE,
    is_major_market BOOLEAN DEFAULT FALSE,
    is_emerging_market BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_TAG: Dimensão de tags com análise da comunidade
CREATE TABLE IF NOT EXISTS public_marts.dim_tag (
    tag_key SERIAL PRIMARY KEY,
    tag_id INT NOT NULL,                         -- Natural key
    tag_name VARCHAR(255) NOT NULL,
    tag_name_clean VARCHAR(255),
    -- Categorização da tag
    tag_category VARCHAR(100),                   -- Gameplay, Theme, Mood, Technical, Social
    tag_type VARCHAR(50),                        -- Descriptive, Mood, Feature, Genre-like
    -- Métricas da tag
    total_games INT DEFAULT 0,
    avg_votes_per_game DECIMAL(10,2),
    total_votes BIGINT DEFAULT 0,
    avg_game_quality DECIMAL(5,2),
    avg_game_price DECIMAL(10,2),
    -- Análise de tendência
    popularity_trend VARCHAR(30),               -- Rising, Stable, Declining
    niche_score DECIMAL(5,2),                   -- Quão nicho é a tag
    commercial_appeal DECIMAL(5,2),             -- Apelo comercial da tag
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DIM_PRICE_SEGMENT: Dimensão de segmentos de preço
CREATE TABLE IF NOT EXISTS public_marts.dim_price_segment (
    price_segment_key SERIAL PRIMARY KEY,
    segment_name VARCHAR(50) NOT NULL,
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    description TEXT,
    target_market VARCHAR(50),                  -- Casual, Budget-conscious, Premium, Collector
    typical_quality_level VARCHAR(30),          -- Basic, Standard, Premium, Luxury
    market_penetration VARCHAR(30),             -- Low, Medium, High, Dominant
    sort_order INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA FATO CENTRAL

-- FACT_GAMES: FATO CENTRAL - ALTA E FINA
-- Apenas métricas numéricas e chaves estrangeiras (sem relacionamentos complexos)
CREATE TABLE IF NOT EXISTS public_marts.fact_games (
    fact_key SERIAL PRIMARY KEY,
    
    -- CHAVES ESTRANGEIRAS (dimensões principais)
    game_key INT NOT NULL,
    release_date_key INT,
    price_segment_key INT,
    primary_developer_key INT,
    primary_publisher_key INT,
    primary_genre_key INT,
    primary_category_key INT,
    primary_tag_key INT,
    primary_language_key INT,
    
    -- MÉTRICAS PURAS (apenas números e medidas)
    
    -- Métricas de preço
    current_price DECIMAL(10,2),
    original_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    
    -- Métricas de popularidade
    estimated_owners_min BIGINT,
    estimated_owners_max BIGINT,
    estimated_owners_avg BIGINT,
    peak_ccu INT,
    
    -- Métricas de avaliação
    metacritic_score INT,
    user_score DECIMAL(3,2),
    positive_reviews BIGINT,
    negative_reviews BIGINT,
    total_reviews BIGINT,
    review_score_percent DECIMAL(5,2),
    
    -- Métricas de engajamento  
    average_playtime_forever INT,
    average_playtime_two_weeks INT,
    median_playtime_forever INT,
    median_playtime_two_weeks INT,
    recommendations INT,
    
    -- Contadores simples (relacionamentos agregados)
    total_developers_count SMALLINT DEFAULT 1,
    total_publishers_count SMALLINT DEFAULT 1,
    total_genres_count SMALLINT DEFAULT 1,
    total_categories_count SMALLINT DEFAULT 0,
    total_tags_count SMALLINT DEFAULT 0,
    total_languages_count SMALLINT DEFAULT 0,
    
    -- Flags simples (apenas boolean)
    has_achievements BOOLEAN DEFAULT FALSE,
    has_dlc BOOLEAN DEFAULT FALSE,
    has_trading_cards BOOLEAN DEFAULT FALSE,
    has_workshop BOOLEAN DEFAULT FALSE,
    has_multiple_languages BOOLEAN DEFAULT FALSE,
    has_controller_support BOOLEAN DEFAULT FALSE,
    is_vr_supported BOOLEAN DEFAULT FALSE,
    is_early_access BOOLEAN DEFAULT FALSE,
    
    -- Scores calculados (apenas números)
    popularity_score DECIMAL(10,4),
    engagement_score DECIMAL(10,4),
    commercial_success_score DECIMAL(10,4),
    quality_score DECIMAL(5,2),
    
    -- Rankings (números simples)
    global_popularity_rank INT,
    genre_popularity_rank INT,
    quality_rank_overall INT,
    
    -- Metadados mínimos
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- CONSTRAINTS
    FOREIGN KEY (game_key) REFERENCES public_marts.dim_game(game_key),
    FOREIGN KEY (release_date_key) REFERENCES public_marts.dim_date(date_key),
    FOREIGN KEY (price_segment_key) REFERENCES public_marts.dim_price_segment(price_segment_key),
    FOREIGN KEY (primary_developer_key) REFERENCES public_marts.dim_developer(developer_key),
    FOREIGN KEY (primary_publisher_key) REFERENCES public_marts.dim_publisher(publisher_key),
    FOREIGN KEY (primary_genre_key) REFERENCES public_marts.dim_genre(genre_key),
    FOREIGN KEY (primary_category_key) REFERENCES public_marts.dim_category(category_key),
    FOREIGN KEY (primary_tag_key) REFERENCES public_marts.dim_tag(tag_key),
    FOREIGN KEY (primary_language_key) REFERENCES public_marts.dim_language(language_key)
);

-- ÍNDICES OTIMIZADOS PARA PERFORMANCE

-- Índices para fact_games 
CREATE INDEX IF NOT EXISTS idx_fact_game_key ON public_marts.fact_games(game_key);
CREATE INDEX IF NOT EXISTS idx_fact_date_key ON public_marts.fact_games(release_date_key);
CREATE INDEX IF NOT EXISTS idx_fact_price_segment ON public_marts.fact_games(price_segment_key);
CREATE INDEX IF NOT EXISTS idx_fact_primary_developer ON public_marts.fact_games(primary_developer_key);
CREATE INDEX IF NOT EXISTS idx_fact_primary_publisher ON public_marts.fact_games(primary_publisher_key);
CREATE INDEX IF NOT EXISTS idx_fact_primary_genre ON public_marts.fact_games(primary_genre_key);

-- Índices para métricas principais (consultas analíticas)
CREATE INDEX IF NOT EXISTS idx_fact_scores ON public_marts.fact_games(metacritic_score, user_score);
CREATE INDEX IF NOT EXISTS idx_fact_popularity ON public_marts.fact_games(popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_fact_engagement ON public_marts.fact_games(engagement_score DESC);
CREATE INDEX IF NOT EXISTS idx_fact_commercial ON public_marts.fact_games(commercial_success_score DESC);
CREATE INDEX IF NOT EXISTS idx_fact_quality ON public_marts.fact_games(quality_score DESC);

-- Índices para métricas de negócio
CREATE INDEX IF NOT EXISTS idx_fact_price ON public_marts.fact_games(current_price);
CREATE INDEX IF NOT EXISTS idx_fact_owners ON public_marts.fact_games(estimated_owners_avg DESC);
CREATE INDEX IF NOT EXISTS idx_fact_reviews ON public_marts.fact_games(total_reviews DESC);

-- Índices para flags (filtros comuns)
CREATE INDEX IF NOT EXISTS idx_fact_achievements ON public_marts.fact_games(has_achievements) WHERE has_achievements = true;
CREATE INDEX IF NOT EXISTS idx_fact_vr ON public_marts.fact_games(is_vr_supported) WHERE is_vr_supported = true;
CREATE INDEX IF NOT EXISTS idx_fact_early_access ON public_marts.fact_games(is_early_access) WHERE is_early_access = true;

-- Índices compostos para consultas comuns
CREATE INDEX IF NOT EXISTS idx_fact_genre_popularity ON public_marts.fact_games(primary_genre_key, popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_fact_developer_quality ON public_marts.fact_games(primary_developer_key, quality_score DESC);
CREATE INDEX IF NOT EXISTS idx_fact_date_scores ON public_marts.fact_games(release_date_key, quality_score DESC, popularity_score DESC);

-- Índices para dimensões
CREATE INDEX IF NOT EXISTS idx_dim_game_app_id ON public_marts.dim_game(app_id);
CREATE INDEX IF NOT EXISTS idx_dim_game_current ON public_marts.dim_game(is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_dim_game_name ON public_marts.dim_game(name);
CREATE INDEX IF NOT EXISTS idx_dim_game_categories ON public_marts.dim_game(market_position, target_audience, success_tier);

CREATE INDEX IF NOT EXISTS idx_dim_developer_id ON public_marts.dim_developer(developer_id);
CREATE INDEX IF NOT EXISTS idx_dim_developer_tier ON public_marts.dim_developer(developer_tier, reputation_score DESC);

CREATE INDEX IF NOT EXISTS idx_dim_publisher_id ON public_marts.dim_publisher(publisher_id);
CREATE INDEX IF NOT EXISTS idx_dim_publisher_tier ON public_marts.dim_publisher(publisher_tier, reputation_score DESC);

CREATE INDEX IF NOT EXISTS idx_dim_genre_id ON public_marts.dim_genre(genre_id);
CREATE INDEX IF NOT EXISTS idx_dim_genre_market ON public_marts.dim_genre(market_share_percent DESC, popularity_rank);

CREATE INDEX IF NOT EXISTS idx_dim_category_id ON public_marts.dim_category(category_id);
CREATE INDEX IF NOT EXISTS idx_dim_language_id ON public_marts.dim_language(language_id);
CREATE INDEX IF NOT EXISTS idx_dim_tag_id ON public_marts.dim_tag(tag_id);

-- Índices para data dimension
CREATE INDEX IF NOT EXISTS idx_dim_date_year_month ON public_marts.dim_date(year, month);
CREATE INDEX IF NOT EXISTS idx_dim_date_quarter ON public_marts.dim_date(fiscal_year, fiscal_quarter);
CREATE INDEX IF NOT EXISTS idx_dim_date_season ON public_marts.dim_date(season, year);

-- POPULAÇÃO INICIAL DOS SEGMENTOS DE PREÇO

INSERT INTO public_marts.dim_price_segment (segment_name, min_price, max_price, description, target_market, typical_quality_level, market_penetration, sort_order) VALUES
('Free', 0.00, 0.00, 'Jogos gratuitos', 'Casual', 'Basic', 'High', 1),
('Budget', 0.01, 9.99, 'Jogos de orçamento baixo', 'Budget-conscious', 'Basic', 'High', 2),
('Economy', 10.00, 19.99, 'Jogos econômicos', 'Budget-conscious', 'Standard', 'Medium', 3),
('Standard', 20.00, 39.99, 'Jogos padrão', 'Core', 'Standard', 'High', 4),
('Premium', 40.00, 59.99, 'Jogos premium', 'Core', 'Premium', 'Medium', 5),
('AAA', 60.00, 79.99, 'Jogos AAA', 'Core', 'Premium', 'Medium', 6),
('Luxury', 80.00, 999.99, 'Jogos de luxo/colecionador', 'Collector', 'Luxury', 'Low', 7)
ON CONFLICT DO NOTHING;

-- VIEWS ÚTEIS PARA ANÁLISES RÁPIDAS

-- View para análise de gêneros 
CREATE OR REPLACE VIEW public_marts.view_genre_analytics AS
WITH genre_metrics AS (
    SELECT 
        g.genre_key,
        g.name AS genre_name,
        g.genre_maturity AS genre_category, -- Usando genre_maturity como genre_category
        g.total_games,
        g.avg_price,
        g.avg_metacritic_score,
        g.avg_user_score,
        
        -- Métricas calculadas da tabela fato
        COUNT(f.fact_key) as total_games_in_fact,
        AVG(f.popularity_score) as avg_popularity_score,
        AVG(f.quality_score) as avg_quality_score,
        AVG(f.engagement_score) as avg_engagement_score,
        AVG(f.commercial_success_score) as avg_commercial_success_score,
        
        -- Contagens por categorias de sucesso
        COUNT(CASE WHEN f.quality_score > 80 THEN 1 END) as high_quality_games_count,
        COUNT(CASE WHEN f.popularity_score > 70 THEN 1 END) as hit_games_count,
        COUNT(CASE WHEN f.current_price = 0 THEN 1 END) as free_games_count,
        
        -- Métricas de mercado
        SUM(f.estimated_owners_avg) as total_estimated_owners,
        AVG(f.current_price) as avg_current_price,
        SUM(f.total_reviews) as total_reviews,
        AVG(f.review_score_percent) as avg_review_score_percent,
        
        -- Métricas de engajamento
        AVG(f.average_playtime_forever) as avg_playtime_forever,
        SUM(f.recommendations) as total_recommendations
        
    FROM public_marts.dim_genre g
    LEFT JOIN public_marts.fact_games f ON g.genre_key = f.primary_genre_key
    GROUP BY 
        g.genre_key, g.name, g.genre_maturity, g.total_games, g.avg_price, 
        g.avg_metacritic_score, g.avg_user_score
),

genre_with_market_share AS (
    SELECT 
        *,
        ROUND(
            (total_games_in_fact::DECIMAL / SUM(total_games_in_fact) OVER()) * 100, 
            2
        ) as market_share_percent,
        CURRENT_TIMESTAMP as created_at
    FROM genre_metrics
)

SELECT * FROM genre_with_market_share
ORDER BY avg_popularity_score DESC NULLS LAST;

-- View para análise temporal
CREATE OR REPLACE VIEW public_marts.view_temporal_analytics AS
WITH date_base AS (
    SELECT 
        date_key,
        year as year,
        month as month,
        month_name,
        quarter as quarter,
        season as season
    FROM public_marts.dim_date
    WHERE date_key != 99991231  -- Excluir datas desconhecida
),

temporal_metrics AS (
    SELECT 
        d.date_key,
        d.year,
        d.month,
        d.month_name,
        d.quarter,
        d.season,
        CONCAT(d.year, '-', LPAD(d.month::TEXT, 2, '0')) as year_month,
        
        -- Contagens de jogos
        COUNT(f.fact_key) as total_games_released,
        COUNT(CASE WHEN f.quality_score > 80 THEN 1 END) as high_quality_games_count,
        COUNT(CASE WHEN f.popularity_score > 70 THEN 1 END) as hit_games_count,
        COUNT(CASE WHEN f.current_price = 0 THEN 1 END) as free_games_count,
        
        -- Scores médios
        AVG(f.popularity_score) as avg_popularity_score,
        AVG(f.engagement_score) as avg_engagement_score,
        AVG(f.commercial_success_score) as avg_commercial_success_score,
        AVG(f.quality_score) as avg_quality_score,
        MAX(f.popularity_score) as max_popularity_score,
        
        -- Métricas financeiras
        SUM(f.estimated_owners_avg * f.current_price) as total_revenue_estimate,
        AVG(f.current_price) as avg_price,
        SUM(f.estimated_owners_avg) as total_owners_estimate,
        
        -- Métricas de qualidade e reviews
        AVG(f.review_score_percent) as avg_review_score,
        SUM(f.positive_reviews) as total_positive_reviews,
        SUM(f.total_reviews) as total_reviews,
        
        -- Métricas de engajamento
        AVG(f.average_playtime_forever) as avg_playtime,
        SUM(f.recommendations) as total_recommendations,
        
        -- Distribuição por segmento de preço
        COUNT(CASE WHEN f.price_segment_key = 1 THEN 1 END) as free_segment_count,
        COUNT(CASE WHEN f.price_segment_key = 2 THEN 1 END) as budget_segment_count,
        COUNT(CASE WHEN f.price_segment_key = 4 THEN 1 END) as standard_segment_count,
        COUNT(CASE WHEN f.price_segment_key IN (6,7) THEN 1 END) as premium_segment_count,
        
        -- Estatísticas de desenvolvimento
        AVG(f.total_developers_count) as avg_developers_per_game,
        AVG(f.total_genres_count) as avg_genres_per_game
        
    FROM date_base d
    LEFT JOIN public_marts.fact_games f ON d.date_key = f.release_date_key
    GROUP BY 
        d.date_key, d.year, d.month, d.month_name, d.quarter, d.season
),

temporal_final AS (
    SELECT 
        *,
        -- Taxa de reviews positivos calculada
        CASE 
            WHEN total_reviews > 0 
            THEN ROUND((total_positive_reviews::DECIMAL / total_reviews) * 100, 2)
            ELSE NULL 
        END as positive_review_rate,
        CURRENT_TIMESTAMP as created_at
    FROM temporal_metrics
)

SELECT * FROM temporal_final
ORDER BY year DESC, month DESC;

-- View para análise de desenvolvedores
CREATE OR REPLACE VIEW public_marts.view_developer_performance AS
WITH developer_metrics AS (
    SELECT 
        dev.developer_key,
        dev.name as developer_name,
        dev.developer_tier,
        dev.reputation_score,
        dev.total_games as dim_total_games,
        dev.avg_metacritic_score as dim_avg_metacritic_score,
        dev.avg_user_score as dim_avg_user_score,
        
        -- Métricas calculadas da tabela fato
        COUNT(f.fact_key) as total_games_in_fact,
        AVG(f.quality_score) as avg_quality_score,
        AVG(f.popularity_score) as avg_popularity_score,
        AVG(f.engagement_score) as avg_engagement_score,
        AVG(f.commercial_success_score) as avg_commercial_success_score,
        MAX(f.popularity_score) as best_game_popularity,
        
        -- Métricas de sucesso
        COUNT(CASE WHEN f.quality_score > 80 THEN 1 END) as high_quality_games_count,
        COUNT(CASE WHEN f.popularity_score > 70 THEN 1 END) as hit_games_count,
        COUNT(CASE WHEN f.current_price = 0 THEN 1 END) as free_games_count,
        
        -- Métricas financeiras
        SUM(f.estimated_owners_avg * f.current_price) as total_revenue_estimate,
        AVG(f.current_price) as avg_current_price,
        SUM(f.estimated_owners_avg) as total_estimated_owners,
        
        -- Métricas de qualidade
        AVG(f.review_score_percent) as avg_review_score,
        SUM(f.total_reviews) as total_reviews,
        AVG(f.metacritic_score) as avg_metacritic_from_facts,
        
        -- Métricas de engajamento
        AVG(f.average_playtime_forever) as avg_playtime_forever,
        SUM(f.recommendations) as total_recommendations,
        
        -- Análise de portfolio
        AVG(f.total_genres_count) as avg_genres_per_game,
        COUNT(DISTINCT f.primary_genre_key) as unique_genres_developed
        
    FROM public_marts.dim_developer dev
    LEFT JOIN public_marts.fact_games f ON dev.developer_key = f.primary_developer_key
    GROUP BY 
        dev.developer_key, dev.name, dev.developer_tier, dev.reputation_score, 
        dev.total_games, dev.avg_metacritic_score, dev.avg_user_score
),

developer_final AS (
    SELECT 
        *,
        -- Taxa de sucesso calculada
        CASE 
            WHEN total_games_in_fact > 0 
            THEN ROUND((hit_games_count::DECIMAL / total_games_in_fact) * 100, 2)
            ELSE 0 
        END as success_rate_percent,
        CURRENT_TIMESTAMP as created_at
    FROM developer_metrics
)

SELECT * FROM developer_final
ORDER BY avg_quality_score DESC NULLS LAST;

COMMENT ON VIEW public_marts.view_genre_analytics IS 'View para análise de gêneros com métricas de popularidade, qualidade, engajamento e mercado';
COMMENT ON VIEW public_marts.view_temporal_analytics IS 'View para análise temporal das tendências de jogos por período (ano, mês, temporada)';
COMMENT ON VIEW public_marts.view_developer_performance IS 'View para análise de desenvolvedores com métricas de performance, qualidade e financeiras';

-- COMENTÁRIOS

COMMENT ON SCHEMA public_staging IS 'Schema para modelos de staging (transformações iniciais do DBT)';
COMMENT ON SCHEMA public_marts IS 'Schema para data marts (modelo estrela simplificado do DW)';
COMMENT ON SCHEMA raw IS 'Schema para dados brutos/seeds do DBT';
COMMENT ON SCHEMA snapshots IS 'Schema para snapshots/histórico de dados do DBT';

COMMENT ON TABLE public_marts.fact_games IS 'TABELA FATO CENTRAL';
COMMENT ON TABLE public_marts.dim_game IS 'Dimensão principal dos jogos categorização avançada';
COMMENT ON TABLE public_marts.dim_developer IS 'Dimensão de desenvolvedores com métricas agregadas e categorização';
COMMENT ON TABLE public_marts.dim_publisher IS 'Dimensão de publicadores com análise de mercado';
COMMENT ON TABLE public_marts.dim_genre IS 'Dimensão de gêneros com análise de mercado e maturidade';
COMMENT ON TABLE public_marts.dim_category IS 'Dimensão de categorias com tipologia e impacto';
COMMENT ON TABLE public_marts.dim_language IS 'Dimensão de idiomas com análise de mercado e priorização';
COMMENT ON TABLE public_marts.dim_tag IS 'Dimensão de tags com categorização e análise de tendências';
COMMENT ON TABLE public_marts.dim_date IS 'Dimensão de tempo completa';
COMMENT ON TABLE public_marts.dim_price_segment IS 'Dimensão de segmentos de preço com análise de mercado';

COMMENT ON VIEW public_marts.view_genre_analytics IS 'View para agregações de gênero - análise em tempo real';
COMMENT ON VIEW public_marts.view_temporal_analytics IS 'View para agregações temporais - análise em tempo real';
COMMENT ON VIEW public_marts.view_developer_performance IS 'View para análise de performance de desenvolvedores';