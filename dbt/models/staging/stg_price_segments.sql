-- STG_PRICE_SEGMENTS: Staging model para segmentos de preço (baseado na estrutura fixa)

WITH free_segment AS (
    SELECT 
        1 as price_segment_key,
        'Free' as segment_name,
        0.00 as min_price,
        0.00 as max_price,
        'Jogos gratuitos com possíveis microtransações' as description,
        'Casual' as target_market,
        'Basic' as typical_quality_level,
        'High' as market_penetration,
        1 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

budget_segment AS (
    SELECT 
        2 as price_segment_key,
        'Budget' as segment_name,
        0.01 as min_price,
        9.99 as max_price,
        'Jogos de baixo custo, indies ou antigos' as description,
        'Budget-conscious' as target_market,
        'Basic' as typical_quality_level,
        'High' as market_penetration,
        2 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

economy_segment AS (
    SELECT 
        3 as price_segment_key,
        'Economy' as segment_name,
        10.00 as min_price,
        19.99 as max_price,
        'Jogos de preço acessível, boa relação custo-benefício' as description,
        'Budget-conscious' as target_market,
        'Standard' as typical_quality_level,
        'Medium' as market_penetration,
        3 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

standard_segment AS (
    SELECT 
        4 as price_segment_key,
        'Standard' as segment_name,
        20.00 as min_price,
        39.99 as max_price,
        'Preço padrão para jogos mainstream' as description,
        'Core' as target_market,
        'Standard' as typical_quality_level,
        'High' as market_penetration,
        4 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

premium_segment AS (
    SELECT 
        5 as price_segment_key,
        'Premium' as segment_name,
        40.00 as min_price,
        59.99 as max_price,
        'Jogos premium, franquias estabelecidas' as description,
        'Core' as target_market,
        'Premium' as typical_quality_level,
        'Medium' as market_penetration,
        5 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

aaa_segment AS (
    SELECT 
        6 as price_segment_key,
        'AAA' as segment_name,
        60.00 as min_price,
        79.99 as max_price,
        'Blockbusters AAA, lançamentos major' as description,
        'Core' as target_market,
        'Premium' as typical_quality_level,
        'Medium' as market_penetration,
        6 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

luxury_segment AS (
    SELECT 
        7 as price_segment_key,
        'Luxury' as segment_name,
        80.00 as min_price,
        999.99 as max_price,
        'Edições especiais, colecionáveis' as description,
        'Collector' as target_market,
        'Luxury' as typical_quality_level,
        'Low' as market_penetration,
        7 as sort_order,
        CURRENT_TIMESTAMP as loaded_at
),

combined_segments AS (
    SELECT * FROM free_segment
    UNION ALL
    SELECT * FROM budget_segment
    UNION ALL
    SELECT * FROM economy_segment
    UNION ALL
    SELECT * FROM standard_segment
    UNION ALL
    SELECT * FROM premium_segment
    UNION ALL
    SELECT * FROM aaa_segment
    UNION ALL
    SELECT * FROM luxury_segment
)

SELECT * FROM combined_segments
