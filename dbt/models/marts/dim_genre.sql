-- DIM_GENRE: Dimensão de gêneros

WITH genres_base AS (
    SELECT 
        genre_id,
        genre_name,
        genre_category,
        total_games,
        primary_genre_games,
        avg_price,
        median_price,
        min_price,
        max_price,
        avg_metacritic_score,
        avg_user_score,
        avg_review_percent,
        avg_estimated_owners,
        avg_playtime_forever,
        avg_achievements,
        avg_dlc_count,
        all_ages_count,
        kids_count,
        teen_count,
        mature_count,
        free_games_percent,
        latest_release_date,
        earliest_release_date
    FROM {{ ref('stg_genres') }}
    WHERE genre_id IS NOT NULL
      AND genre_name IS NOT NULL
),

genres_final AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY genre_id) as genre_key,
        genre_id,
        genre_name,
        genre_name as genre_name_clean,
        genre_category,
        total_games,
        primary_genre_games as total_primary_genre_games,
        avg_price,
        median_price,
        min_price,
        max_price,
        avg_metacritic_score,
        avg_user_score,
        avg_review_percent as avg_review_score,
        avg_estimated_owners,
        avg_playtime_forever as avg_playtime,
        avg_achievements,
        avg_dlc_count,
        all_ages_count,
        kids_count,
        teen_count,
        mature_count,
        free_games_percent,
        latest_release_date,
        earliest_release_date,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
    FROM genres_base
),

default_record AS (
    SELECT 
        -1 as genre_key,
        -1 as genre_id,
        'Unknown Genre' as genre_name,
        'Unknown Genre' as genre_name_clean,
        'Unknown' as genre_category,
        0 as total_games,
        0 as total_primary_genre_games,
        0.0 as avg_price,
        0.0 as median_price,
        0.0 as min_price,
        0.0 as max_price,
        0.0 as avg_metacritic_score,
        0.0 as avg_user_score,
        0.0 as avg_review_score,
        0.0 as avg_estimated_owners,
        0.0 as avg_playtime,
        0.0 as avg_achievements,
        0.0 as avg_dlc_count,
        0 as all_ages_count,
        0 as kids_count,
        0 as teen_count,
        0 as mature_count,
        0.0 as free_games_percent,
        NULL::DATE as latest_release_date,
        NULL::DATE as earliest_release_date,
        CURRENT_TIMESTAMP as created_at,
        CURRENT_TIMESTAMP as updated_at
)

SELECT * FROM genres_final
UNION ALL
SELECT * FROM default_record
