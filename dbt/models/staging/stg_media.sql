-- Staging model para mídia dos jogos

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        game_id,
        media_type,
        url,
        is_primary,
        order_index
    FROM steam_source.media
    WHERE game_id IS NOT NULL
      AND url IS NOT NULL 
      AND TRIM(url) != ''
      AND media_type IS NOT NULL 
      AND TRIM(media_type) != ''
),

url_cleaning AS (
    -- Limpeza e padronização das URLs
    SELECT 
        *,
        TRIM(url) as media_url_clean,
        LENGTH(url) as url_length,
        CASE 
            WHEN url LIKE 'http%' THEN TRUE
            ELSE FALSE
        END as is_valid_url,
        CASE 
            WHEN url LIKE '%steam%' THEN 'Steam CDN'
            WHEN url LIKE '%youtube%' THEN 'YouTube'
            WHEN url LIKE '%vimeo%' THEN 'Vimeo'
            WHEN url LIKE '%cdn%' THEN 'CDN'
            ELSE 'Other'
        END as url_host_type
    FROM source_data
),

media_classification AS (
    -- Classificação e categorização da mídia
    SELECT 
        *,
        UPPER(TRIM(media_type)) as media_type_clean,
        CASE 
            WHEN LOWER(media_type) LIKE '%image%' OR LOWER(media_type) LIKE '%screenshot%' THEN 'Image'
            WHEN LOWER(media_type) LIKE '%video%' OR LOWER(media_type) LIKE '%trailer%' THEN 'Video'
            WHEN LOWER(media_type) LIKE '%header%' OR LOWER(media_type) LIKE '%logo%' THEN 'Promotional'
            ELSE 'Other'
        END as media_category,
        -- Prioridade baseada no tipo e se é primária
        CASE 
            WHEN is_primary = TRUE THEN 100
            WHEN LOWER(media_type) LIKE '%header%' THEN 90
            WHEN LOWER(media_type) LIKE '%screenshot%' THEN 80
            WHEN LOWER(media_type) LIKE '%video%' THEN 70
            ELSE 50
        END as media_priority
    FROM url_cleaning
),

final_output AS (
    -- Finalizando com flags de qualidade adicionais
    SELECT
        game_id,
        media_type,
        url as media_url,
        is_primary,
        order_index,
        media_url_clean,
        url_length,
        media_type_clean,
        media_category,
        
        -- Flags de qualidade
        CASE 
            WHEN url IS NULL OR TRIM(url) = '' THEN TRUE
            ELSE FALSE
        END as is_url_missing,
        
        is_valid_url,
        
        CASE 
            WHEN media_type IS NULL OR TRIM(media_type) = '' THEN TRUE
            ELSE FALSE
        END as is_media_type_missing,
        
        url_host_type,
        media_priority,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM media_classification
)

SELECT * FROM final_output
