-- DIM_PRICE_SEGMENT: Dimensão de segmentos de preço

WITH price_segments_base AS (
    SELECT 
        price_segment_key,
        segment_name as name,
        min_price,
        max_price,
        description,
        target_market,
        typical_quality_level,
        market_penetration,
        sort_order
    FROM {{ ref('stg_price_segments') }}
    WHERE price_segment_key IS NOT NULL
      AND segment_name IS NOT NULL
),

price_segments_enriched AS (
    SELECT 
        *,
        
        -- ANÁLISES DE FAIXAS DE PREÇO
        CASE 
            WHEN min_price = 0 AND max_price = 0 THEN 'Free-to-Play'
            WHEN max_price <= 5 THEN 'Ultra Budget'
            WHEN max_price <= 15 THEN 'Budget Friendly'
            WHEN max_price <= 30 THEN 'Mainstream'
            WHEN max_price <= 60 THEN 'Premium'
            ELSE 'Luxury'
        END as price_category,
        
        CASE 
            WHEN min_price = 0 AND max_price = 0 THEN 'Monetization through microtransactions, ads, or DLC'
            WHEN max_price <= 10 THEN 'Impulse purchase price range with low barrier to entry'
            WHEN max_price <= 25 THEN 'Considered purchase requiring moderate budget planning'
            WHEN max_price <= 60 THEN 'Premium purchase requiring budget allocation'
            ELSE 'Luxury purchase for enthusiasts and collectors'
        END as purchasing_psychology,
        
        CASE 
            WHEN min_price = 0 THEN 'No upfront cost, revenue from post-purchase'
            WHEN max_price <= 5 THEN 'Minimal financial risk for consumers'
            WHEN max_price <= 20 THEN 'Low to moderate financial commitment'
            WHEN max_price <= 50 THEN 'Moderate to high financial commitment'
            ELSE 'High financial commitment requiring deliberation'
        END as financial_commitment_level,
        
        -- ANÁLISES DE MERCADO E COMPETIÇÃO
        CASE 
            WHEN min_price = 0 AND max_price = 0 THEN 'Very High'
            WHEN max_price <= 15 THEN 'High'
            WHEN max_price <= 40 THEN 'Medium'
            ELSE 'Low'
        END as market_competition_level,
        
        CASE 
            WHEN min_price = 0 THEN 'F2P Model'
            WHEN max_price <= 10 THEN 'Volume Sales'
            WHEN max_price <= 30 THEN 'Balanced Revenue'
            WHEN max_price <= 60 THEN 'Premium Revenue'
            ELSE 'Niche/Collector Revenue'
        END as revenue_strategy,
        
        -- CARACTERÍSTICAS DO CONSUMIDOR
        CASE 
            WHEN min_price = 0 THEN 'Broad appeal across all demographics'
            WHEN max_price <= 10 THEN 'Price-sensitive and casual gamers'
            WHEN max_price <= 25 THEN 'Mainstream gaming audience'
            WHEN max_price <= 60 THEN 'Dedicated gaming enthusiasts'
            ELSE 'Hardcore enthusiasts and collectors'
        END as target_consumer_profile,
        
        CASE 
            WHEN min_price = 0 THEN 'Very Low'
            WHEN max_price <= 5 THEN 'Low'
            WHEN max_price <= 20 THEN 'Medium'
            WHEN max_price <= 50 THEN 'High'
            ELSE 'Very High'
        END as purchase_decision_complexity
    FROM price_segments_base
)

SELECT 
    price_segment_key,
    name,
    
    -- INFORMAÇÕES BÁSICAS
    description,
    min_price,
    max_price,
    CASE 
        WHEN max_price = min_price THEN min_price
        ELSE ROUND((min_price + max_price) / 2.0, 2)
    END as midpoint_price,
    
    CASE 
        WHEN min_price = 0 AND max_price = 0 THEN 0
        ELSE max_price - min_price
    END as price_range_width,
    
    -- CLASSIFICAÇÕES E CATEGORIAS
    price_category,
    target_market,
    typical_quality_level,
    market_penetration,
    
    -- ANÁLISES DE COMPORTAMENTO DO CONSUMIDOR
    purchasing_psychology,
    financial_commitment_level,
    target_consumer_profile,
    purchase_decision_complexity,
    
    CASE 
        WHEN min_price = 0 THEN 'Immediate'
        WHEN max_price <= 5 THEN 'Impulse'
        WHEN max_price <= 15 THEN 'Quick Decision'
        WHEN max_price <= 40 THEN 'Considered Purchase'
        ELSE 'Research-heavy Purchase'
    END as typical_purchase_behavior,
    
    CASE 
        WHEN min_price = 0 THEN 'High (F2P conversion)'
        WHEN max_price <= 10 THEN 'Medium-High (low risk)'
        WHEN max_price <= 30 THEN 'Medium (price sensitive)'
        ELSE 'Low (price selective)'
    END as conversion_likelihood,
    
    -- ANÁLISES DE MERCADO E ESTRATÉGIA
    market_competition_level,
    revenue_strategy,
    
    CASE 
        WHEN min_price = 0 THEN 'User Acquisition Focus'
        WHEN max_price <= 10 THEN 'Volume-based Strategy'
        WHEN max_price <= 30 THEN 'Balanced Revenue Strategy'
        WHEN max_price <= 60 THEN 'Premium Positioning'
        ELSE 'Niche/Luxury Positioning'
    END as business_strategy_type,
    
    CASE 
        WHEN min_price = 0 THEN 'Post-purchase monetization required'
        WHEN max_price <= 10 THEN 'High volume sales needed for profitability'
        WHEN max_price <= 30 THEN 'Moderate volume with good margins'
        WHEN max_price <= 60 THEN 'Low volume with premium margins'
        ELSE 'Very low volume with luxury margins'
    END as profitability_model,
    
    -- ANÁLISES DE DESENVOLVIMENTO E PRODUÇÃO
    CASE 
        WHEN min_price = 0 THEN 'High (ongoing content needed)'
        WHEN max_price <= 10 THEN 'Low (simple mechanics acceptable)'
        WHEN max_price <= 30 THEN 'Medium (balanced features expected)'
        WHEN max_price <= 60 THEN 'High (premium features expected)'
        ELSE 'Very High (exceptional quality required)'
    END as development_expectation,
    
    CASE 
        WHEN min_price = 0 THEN 'Ongoing (live service)'
        WHEN max_price <= 15 THEN 'Minimal (bug fixes only)'
        WHEN max_price <= 40 THEN 'Standard (updates and patches)'
        ELSE 'Extended (DLC and expansions)'
    END as post_launch_support_expectation,
    
    CASE 
        WHEN min_price = 0 THEN 'Essential (retention critical)'
        WHEN max_price <= 10 THEN 'Low (word-of-mouth sufficient)'
        WHEN max_price <= 30 THEN 'Medium (standard promotion)'
        WHEN max_price <= 60 THEN 'High (premium marketing)'
        ELSE 'Targeted (niche marketing)'
    END as marketing_investment_need,
    
    -- ANÁLISES DE RISCO E OPORTUNIDADE
    CASE 
        WHEN min_price = 0 THEN 'Low upfront, high execution risk'
        WHEN max_price <= 10 THEN 'Low financial risk, high competition'
        WHEN max_price <= 30 THEN 'Medium risk, balanced opportunity'
        WHEN max_price <= 60 THEN 'High risk, high reward potential'
        ELSE 'Very high risk, niche reward'
    END as risk_profile,
    
    CASE 
        WHEN min_price = 0 THEN 'Very Large'
        WHEN max_price <= 10 THEN 'Large'
        WHEN max_price <= 30 THEN 'Medium'
        WHEN max_price <= 60 THEN 'Small'
        ELSE 'Very Small'
    END as addressable_market_size,
    
    CASE 
        WHEN min_price = 0 THEN 'Platform dependency, monetization challenges'
        WHEN max_price <= 10 THEN 'High competition, margin pressure'
        WHEN max_price <= 30 THEN 'Balanced challenges and opportunities'
        WHEN max_price <= 60 THEN 'Quality expectations, marketing costs'
        ELSE 'Limited market, high expectations'
    END as key_challenges,
    
    -- DADOS DE REFERÊNCIA
    sort_order,
    
    CASE 
        WHEN min_price = 0 THEN 'Mobile, Browser, F2P PC'
        WHEN max_price <= 10 THEN 'Mobile, Casual PC, Retro'
        WHEN max_price <= 30 THEN 'PC, Console (digital), Mainstream'
        WHEN max_price <= 60 THEN 'PC, Console (retail), Premium'
        ELSE 'PC (specialist), Console (collector), VR'
    END as typical_platforms,
    
    CASE 
        WHEN min_price = 0 THEN 'Casual, Puzzle, Social, Simulation'
        WHEN max_price <= 10 THEN 'Indie, Casual, Retro, Puzzle'
        WHEN max_price <= 30 THEN 'Action, Adventure, Strategy, RPG'
        WHEN max_price <= 60 THEN 'AAA Action, RPG, Strategy, Simulation'
        ELSE 'Niche, Simulation, VR, Collector editions'
    END as typical_genres,
    
    CURRENT_TIMESTAMP as created_at,
    CURRENT_TIMESTAMP as updated_at

FROM price_segments_enriched
ORDER BY sort_order
