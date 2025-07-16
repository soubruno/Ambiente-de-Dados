-- Staging model para publicadores de jogos

WITH source_data AS (
    -- Extração dos dados fonte com filtragem inicial
    SELECT 
        id as publisher_id,
        name as publisher_name
    FROM steam_source.publishers
    WHERE name IS NOT NULL 
      AND TRIM(name) != ''
),

cleaned_data AS (
    -- Limpeza e padronização dos nomes
    SELECT 
        publisher_id,
        publisher_name,
        TRIM(UPPER(publisher_name)) as publisher_name_clean,
        LENGTH(publisher_name) as publisher_name_length
    FROM source_data
),

publisher_classification AS (
    -- Classificação e categorização dos publicadores
    SELECT 
        *,
        -- Categorização básica de publishers
        CASE 
            WHEN LOWER(publisher_name) LIKE '%indie%' OR LOWER(publisher_name) LIKE '%independent%' THEN 'Indie'
            WHEN LOWER(publisher_name) IN ('valve', 'steam', 'electronic arts', 'ea', 'ubisoft', 'activision', 'microsoft', 'sony') THEN 'AAA'
            WHEN LOWER(publisher_name) LIKE '%mobile%' OR LOWER(publisher_name) LIKE '%casual%' THEN 'Mobile/Casual'
            ELSE 'Other'
        END as publisher_category
    FROM cleaned_data
),

final_output AS (
    -- Finalizando com flags de qualidade e metadados
    SELECT
        publisher_id,
        publisher_name,
        publisher_name_clean,
        publisher_name_length,
        
        -- Flags de qualidade
        CASE 
            WHEN publisher_name IS NULL OR TRIM(publisher_name) = '' THEN TRUE
            ELSE FALSE
        END as is_name_missing,
        
        publisher_category,
        
        -- Metadados
        CURRENT_TIMESTAMP as loaded_at
    FROM publisher_classification
)

SELECT * FROM final_output
