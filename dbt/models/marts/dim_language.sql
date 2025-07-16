-- DIM_LANGUAGE: Dimensão de idiomas

WITH languages_base AS (
    SELECT 
        language_id,
        language_name,
        language_name_clean,
        language_family,
        estimated_market_size,
        primary_region
    FROM {{ ref('stg_languages') }}
    WHERE language_id IS NOT NULL
      AND language_name IS NOT NULL
),

languages_enriched AS (
    SELECT 
        *,
        CASE 
            WHEN estimated_market_size = 'Very High' THEN 95.0
            WHEN estimated_market_size = 'High' THEN 75.0
            WHEN estimated_market_size = 'Medium' THEN 45.0
            ELSE 15.0
        END as market_penetration_percent,
        CASE
            WHEN LOWER(language_name) LIKE '%english%' THEN TRUE
            ELSE FALSE
        END as is_primary_language
    FROM languages_base
),

languages_final AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY language_id) as language_key,
        language_id,
        language_name,
        language_name_clean,
        language_family,
        estimated_market_size as market_size,
        primary_region,
        0 as total_games, 
        0 as total_supported_games, 
        0 as total_audio_games, 
        0 as total_subtitle_games,
        market_penetration_percent,
        is_primary_language,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
    FROM languages_enriched
)

SELECT * FROM languages_final
