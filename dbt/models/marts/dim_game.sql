-- DIM_GAME: Dimensão de jogos

WITH games_base AS (
    SELECT 
        app_id,
        name,
        short_description,
        about,
        required_age,
        controller_support,
        header_image_url,
        website_url,
        support_url,
        dlc_count,
        achievements_count,
        metacritic_score,
        user_score,
        positive_reviews,
        negative_reviews,
        estimated_owners_min,
        estimated_owners_max,
        current_price,
        is_free,
        release_date
    FROM {{ ref('stg_games') }}
    WHERE app_id IS NOT NULL
      AND name IS NOT NULL
),

games_enriched AS (
    SELECT 
        *,
        CASE 
            WHEN required_age = 0 THEN 'Family'
            WHEN required_age <= 13 THEN 'Teens'
            WHEN required_age <= 17 THEN 'Young Adults'
            ELSE 'Mature'
        END as age_rating_category,
        CASE
            WHEN current_price = 0 OR is_free THEN 'Free'
            WHEN current_price <= 10 THEN 'Budget'
            WHEN current_price <= 30 THEN 'Standard'
            ELSE 'Premium'
        END as price_category,
        CASE
            WHEN metacritic_score >= 90 THEN 'Excellent'
            WHEN metacritic_score >= 80 THEN 'Very Good'
            WHEN metacritic_score >= 70 THEN 'Good'
            WHEN metacritic_score >= 60 THEN 'Mixed'
            ELSE 'Poor'
        END as quality_tier
    FROM games_base
),

games_final AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY app_id) as game_key,
        app_id as game_id,
        name as game_name,
        name as game_name_clean,
        short_description,
        about,
        required_age,
        controller_support,
        header_image_url,
        website_url,
        support_url,
        dlc_count,
        achievements_count,
        metacritic_score,
        user_score,
        positive_reviews,
        negative_reviews,
        estimated_owners_min,
        estimated_owners_max,
        current_price,
        is_free,
        release_date,
        age_rating_category,
        price_category,
        quality_tier,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
    FROM games_enriched
)

SELECT * FROM games_final
