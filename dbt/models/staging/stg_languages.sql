-- Staging model para idiomas dos jogos

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        id as language_id,
        name as language_name
    FROM steam_source.languages
    WHERE name IS NOT NULL 
      AND TRIM(name) != ''
),

cleaned_data AS (
    -- Limpeza e padronização dos dados
    SELECT 
        language_id,
        language_name,
        TRIM(language_name) as language_name_clean,
        UPPER(language_name) as language_name_upper,
        LOWER(language_name) as language_name_lower,
        LENGTH(language_name) as language_name_length
    FROM source_data
),

language_classification AS (
    -- Classificação e categorização dos idiomas
    SELECT 
        *,
        -- Categorização por região/família de idiomas
        CASE 
            WHEN LOWER(language_name) IN ('english', 'american english') THEN 'English'
            WHEN LOWER(language_name) IN ('spanish', 'spanish - spain', 'spanish - latin america') THEN 'Spanish'
            WHEN LOWER(language_name) IN ('portuguese', 'portuguese - brazil', 'brazilian') THEN 'Portuguese'
            WHEN LOWER(language_name) IN ('french', 'french - france') THEN 'French'
            WHEN LOWER(language_name) IN ('german', 'deutsch') THEN 'German'
            WHEN LOWER(language_name) IN ('italian', 'italiano') THEN 'Italian'
            WHEN LOWER(language_name) IN ('russian', 'русский') THEN 'Russian'
            WHEN LOWER(language_name) IN ('chinese', 'simplified chinese', 'traditional chinese', 'mandarin') THEN 'Chinese'
            WHEN LOWER(language_name) IN ('japanese', '日本語') THEN 'Japanese'
            WHEN LOWER(language_name) IN ('korean', '한국어') THEN 'Korean'
            WHEN LOWER(language_name) IN ('arabic', 'العربية') THEN 'Arabic'
            ELSE 'Other'
        END as language_family,
        
        -- Popularidade estimada baseada em uso global
        CASE 
            WHEN LOWER(language_name) IN ('english', 'american english') THEN 'Very High'
            WHEN LOWER(language_name) IN ('spanish', 'chinese', 'french', 'german', 'russian') THEN 'High'
            WHEN LOWER(language_name) IN ('portuguese', 'italian', 'japanese', 'korean') THEN 'Medium'
            ELSE 'Low'
        END as estimated_market_size
    FROM cleaned_data
),

final_output AS (
    -- Finalizando com análises regionais e metadados
    SELECT
        language_id,
        language_name,
        language_name_clean,
        language_name_upper,
        language_name_lower,
        language_name_length,
        
        -- Flags de qualidade
        CASE 
            WHEN language_name IS NULL OR TRIM(language_name) = '' THEN TRUE
            ELSE FALSE
        END as is_name_missing,
        
        language_family,
        estimated_market_size,
        
        -- Região principal
        CASE 
            WHEN LOWER(language_name) LIKE '%english%' OR LOWER(language_name) = 'english' THEN 'Global'
            WHEN LOWER(language_name) LIKE '%spanish%' OR LOWER(language_name) = 'spanish' THEN 'Americas/Europe'
            WHEN LOWER(language_name) LIKE '%portuguese%' OR LOWER(language_name) LIKE '%brazil%' THEN 'Americas'
            WHEN LOWER(language_name) LIKE '%chinese%' OR LOWER(language_name) LIKE '%mandarin%' THEN 'Asia'
            WHEN LOWER(language_name) LIKE '%japanese%' THEN 'Asia'
            WHEN LOWER(language_name) LIKE '%korean%' THEN 'Asia'
            WHEN LOWER(language_name) LIKE '%french%' THEN 'Europe'
            WHEN LOWER(language_name) LIKE '%german%' THEN 'Europe'
            WHEN LOWER(language_name) LIKE '%russian%' THEN 'Europe/Asia'
            WHEN LOWER(language_name) LIKE '%arabic%' THEN 'Middle East'
            ELSE 'Other'
        END as primary_region,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM language_classification
)

SELECT * FROM final_output
