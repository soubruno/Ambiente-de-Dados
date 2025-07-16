-- DIM_DATE: Dimensão temporal 

WITH date_spine AS (
    SELECT 
        date_day,
        EXTRACT(YEAR FROM date_day) as year_number,
        EXTRACT(MONTH FROM date_day) as month_number,
        EXTRACT(DAY FROM date_day) as day_number,
        EXTRACT(QUARTER FROM date_day) as quarter_number,
        EXTRACT(DOW FROM date_day) as day_of_week,
        EXTRACT(DOY FROM date_day) as day_of_year,
        EXTRACT(WEEK FROM date_day) as week_of_year
    FROM (
        SELECT 
            generate_series(
                '2000-01-01'::date,
                CURRENT_DATE + INTERVAL '5 years',
                '1 day'::interval
            )::date as date_day
    ) dates
),

dates_enriched AS (
    SELECT 
        *,
        
        -- INFORMAÇÕES BÁSICAS DE CALENDAR
        TO_CHAR(date_day, 'YYYYMMDD')::INT as date_key,
        TO_CHAR(date_day, 'Month') as month_name,
        TO_CHAR(date_day, 'Mon') as month_name_short,
        TO_CHAR(date_day, 'Day') as day_name,
        TO_CHAR(date_day, 'Dy') as day_name_short,
        
        -- ANÁLISES DE PERÍODOS GAMING
        CASE 
            WHEN month_number IN (11, 12) THEN 'Holiday Season'
            WHEN month_number IN (6, 7, 8) THEN 'Summer Season'
            WHEN month_number IN (3, 4, 5) THEN 'Spring Season'
            ELSE 'Regular Season'
        END as gaming_season,
        
        CASE 
            WHEN month_number = 12 AND day_number >= 20 THEN 'Holiday Rush'
            WHEN month_number = 11 AND day_number >= 20 THEN 'Black Friday'
            WHEN month_number = 7 THEN 'Summer Sale'
            WHEN month_number = 3 THEN 'Spring Sale'
            ELSE 'Regular Period'
        END as sales_period,
        
        -- ANÁLISES DE LANÇAMENTO
        CASE 
            WHEN day_of_week = 2 THEN 'Tuesday Launch' -- Steam releases on Tuesday
            WHEN day_of_week = 5 THEN 'Friday Launch'
            WHEN day_of_week IN (1, 7) THEN 'Weekend Launch'
            ELSE 'Mid-week Launch'
        END as release_day_strategy,
        
        CASE 
            WHEN month_number IN (10, 11) THEN 'Pre-Holiday'
            WHEN month_number = 12 THEN 'Holiday Launch'
            WHEN month_number IN (1, 2) THEN 'Post-Holiday'
            WHEN month_number IN (6, 7, 8) THEN 'Summer Launch'
            WHEN month_number IN (3, 4, 5) THEN 'Spring Launch'
            ELSE 'Fall Launch'
        END as release_timing_strategy,
        
        -- CONTEXTO DE MERCADO GAMING
        CASE 
            WHEN year_number <= 2004 THEN 'Early Steam Era'
            WHEN year_number <= 2009 THEN 'Steam Growth'
            WHEN year_number <= 2014 THEN 'Indie Boom'
            WHEN year_number <= 2019 THEN 'Digital Dominance'
            ELSE 'Modern Era'
        END as gaming_era,
        
        CASE 
            WHEN year_number IN (2008, 2009) THEN 'Financial Crisis'
            WHEN year_number IN (2020, 2021) THEN 'Pandemic Era'
            ELSE 'Normal Market'
        END as economic_context
    FROM date_spine
)

SELECT 
    -- CHAVES E IDENTIFICADORES
    date_key as date_key,
    date_day,
    ROW_NUMBER() OVER (ORDER BY date_day) as date_sk,
    
    -- INFORMAÇÕES BÁSICAS (BAIXA E LARGA)
    year_number,
    month_number,
    day_number,
    quarter_number,
    day_of_week,
    day_of_year,
    week_of_year,
    
    month_name,
    month_name_short,
    day_name,
    day_name_short,
    
    -- Formatações alternativas
    TO_CHAR(date_day, 'YYYY-MM') as year_month,
    TO_CHAR(date_day, 'YYYY-Q') as year_quarter,
    'Q' || quarter_number || ' ' || year_number as quarter_name,
    
    -- INDICADORES TEMPORAIS
    CASE WHEN day_of_week IN (1, 7) THEN TRUE ELSE FALSE END as is_weekend,
    CASE WHEN day_of_week IN (2, 3, 4, 5, 6) THEN TRUE ELSE FALSE END as is_weekday,
    CASE WHEN day_number = 1 THEN TRUE ELSE FALSE END as is_month_start,
    CASE WHEN date_day = (date_trunc('month', date_day) + interval '1 month - 1 day')::date THEN TRUE ELSE FALSE END as is_month_end,
    CASE WHEN month_number = 1 AND day_number = 1 THEN TRUE ELSE FALSE END as is_year_start,
    CASE WHEN month_number = 12 AND day_number = 31 THEN TRUE ELSE FALSE END as is_year_end,
    
    -- CONTEXTO DE GAMING E VENDAS
    gaming_season,
    sales_period,
    release_day_strategy,
    release_timing_strategy,
    gaming_era,
    economic_context,
    
    -- ANÁLISES DE PERFORMANCE COMERCIAL
    CASE 
        WHEN month_number IN (11, 12) THEN 'High Sales Expected'
        WHEN month_number IN (6, 7) THEN 'Summer Sales Expected'
        WHEN month_number IN (1, 2) THEN 'Post-Holiday Low'
        ELSE 'Regular Sales Expected'
    END as sales_expectation,
    
    CASE 
        WHEN day_of_week = 2 THEN 'Optimal Release Day'
        WHEN day_of_week = 5 THEN 'Good Release Day'
        WHEN day_of_week IN (1, 7) THEN 'Risky Release Day'
        ELSE 'Suboptimal Release Day'
    END as release_day_rating,
    
    -- MÉTRICAS DE COMPETIÇÃO
    CASE 
        WHEN month_number IN (10, 11, 12) THEN 'High Competition'
        WHEN month_number IN (6, 7, 8) THEN 'Medium Competition'
        ELSE 'Low Competition'
    END as market_competition_level,
    
    CASE 
        WHEN month_number = 11 AND day_number >= 20 THEN 'Peak Marketing'
        WHEN month_number IN (11, 12) THEN 'High Marketing'
        WHEN month_number IN (6, 7) THEN 'Summer Marketing'
        ELSE 'Regular Marketing'
    END as marketing_intensity,
    
    -- ANÁLISES DE TENDÊNCIAS
    CASE 
        WHEN year_number >= 2020 THEN 'Post-Pandemic'
        WHEN year_number >= 2015 THEN 'Modern Gaming'
        WHEN year_number >= 2010 THEN 'Digital Transition'
        WHEN year_number >= 2005 THEN 'Early Digital'
        ELSE 'Pre-Digital'
    END as technology_era,
    
    CASE 
        WHEN quarter_number = 1 THEN 'Q1 - New Year Launch'
        WHEN quarter_number = 2 THEN 'Q2 - Spring Launch'
        WHEN quarter_number = 3 THEN 'Q3 - Summer/Back-to-School'
        ELSE 'Q4 - Holiday Rush'
    END as quarter_strategy,
    
    -- DADOS RELATIVOS
    date_day - INTERVAL '1 year' as same_day_last_year,
    date_day - INTERVAL '1 month' as same_day_last_month,
    date_day - INTERVAL '7 days' as same_day_last_week,
    
    -- Dias desde marcos importantes
    date_day - '2003-09-12'::date as days_since_steam_launch,
    CURRENT_DATE - date_day as days_from_today,
    
    -- METADADOS
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at

FROM dates_enriched

UNION ALL

-- Registro padrão para datas desconhecidas
SELECT 
    99991231 as date_key,
    '9999-12-31'::date as date_day,
    -1 as date_sk,
    
    -- Informações básicas
    9999 as year_number,
    12 as month_number,
    31 as day_number,
    4 as quarter_number,
    1 as day_of_week,
    365 as day_of_year,
    52 as week_of_year,
    
    'Unknown' as month_name,
    'Unknown' as month_name_short,
    'Unknown' as day_name,
    'Unknown' as day_name_short,
    
    -- Formatações alternativas
    '9999-12' as year_month,
    '9999-4' as year_quarter,
    'Q4 9999' as quarter_name,
    
    -- Indicadores temporais
    FALSE as is_weekend,
    TRUE as is_weekday,
    FALSE as is_month_start,
    TRUE as is_month_end,
    FALSE as is_year_start,
    TRUE as is_year_end,
    
    -- Contexto de gaming
    'Unknown Season' as gaming_season,
    'Unknown Period' as sales_period,
    'Unknown Launch' as release_day_strategy,
    'Unknown Timing' as release_timing_strategy,
    'Unknown Era' as gaming_era,
    'Unknown Context' as economic_context,
    
    -- Análises comerciais
    'Unknown Sales' as sales_expectation,
    'Unknown Release' as release_day_rating,
    'Unknown Competition' as market_competition_level,
    'Unknown Marketing' as marketing_intensity,
    'Unknown Era' as technology_era,
    'Unknown Quarter' as quarter_strategy,
    
    -- Dados relativos
    '9999-12-31'::date - INTERVAL '1 year' as same_day_last_year,
    '9999-12-31'::date - INTERVAL '1 month' as same_day_last_month,
    '9999-12-31'::date - INTERVAL '7 days' as same_day_last_week,
    99999 as days_since_steam_launch,
    -99999 as days_from_today,
    
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at
