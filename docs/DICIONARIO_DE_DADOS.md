# Dicionário de Dados - Banco Steam Games Normalizado
 
## Visão Geral
 
Este dicionário de dados documenta a estrutura do banco de dados Steam Games que foi normalizado a partir de um arquivo CSV original. O banco foi projetado seguindo os princípios de normalização para eliminar redundâncias e garantir a integridade dos dados.
 
## Tabelas Principais
 
### 1. `games`
 
Armazena informações principais sobre os jogos disponíveis na plataforma Steam.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| app_id | INT | Identificador único do jogo na Steam | PRIMARY KEY |
| name | VARCHAR(255) | Nome do jogo | - |
| release_date | DATE | Data de lançamento do jogo | - |
| estimated_owners_min | INT | Estimativa mínima de proprietários | - |
| estimated_owners_max | INT | Estimativa máxima de proprietários | - |
| current_price | DECIMAL(10,2) | Preço atual do jogo | - |
| currency_id | INT | Identificador da moeda do preço | - |
| peak_ccu | INT | Pico de usuários simultâneos | - |
| required_age | INT | Idade mínima requerida | - |
| dlc_count | INT | Quantidade de DLCs disponíveis | - |
| about | TEXT | Descrição detalhada do jogo | - |
| short_description | TEXT | Descrição curta do jogo | - |
| header_image_url | TEXT | URL da imagem de cabeçalho | - |
| website_url | TEXT | URL do site oficial | - |
| support_url | TEXT | URL da página de suporte | - |
| metacritic_score | INT | Pontuação no Metacritic | - |
| metacritic_url | TEXT | URL da página do jogo no Metacritic | - |
| user_score | FLOAT | Pontuação média dos usuários | - |
| positive_reviews | INT | Número de avaliações positivas | - |
| negative_reviews | INT | Número de avaliações negativas | - |
| achievements_count | INT | Número de conquistas disponíveis | - |
| recommendations | INT | Número de recomendações | - |
| average_playtime_forever | INT | Tempo médio de jogo (total) | - |
| average_playtime_two_weeks | INT | Tempo médio de jogo (últimas 2 semanas) | - |
| median_playtime_forever | INT | Tempo mediano de jogo (total) | - |
| median_playtime_two_weeks | INT | Tempo mediano de jogo (últimas 2 semanas) | - |
| game_status | VARCHAR(50) | Status atual do jogo | - |
| is_free | BOOLEAN | Indica se o jogo é gratuito | - |
| controller_support | VARCHAR(50) | Tipo de suporte a controles | - |
 
### 2. `developers`
 
Armazena informações sobre os desenvolvedores de jogos.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| id | INT | Identificador único do desenvolvedor | PRIMARY KEY |
| name | VARCHAR(255) | Nome do desenvolvedor | - |
 
### 3. `publishers`
 
Armazena informações sobre as editoras de jogos.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| id | INT | Identificador único da editora | PRIMARY KEY |
| name | VARCHAR(255) | Nome da editora | - |
 
### 4. `categories`
 
Armazena as categorias de jogos disponíveis na Steam.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| id | INT | Identificador único da categoria | PRIMARY KEY |
| name | VARCHAR(255) | Nome da categoria | - |
 
### 5. `genres`
 
Armazena os gêneros de jogos.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| id | INT | Identificador único do gênero | PRIMARY KEY |
| name | VARCHAR(255) | Nome do gênero | - |
 
### 6. `tags`
 
Armazena as tags atribuídas aos jogos pelos usuários.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| id | INT | Identificador único da tag | PRIMARY KEY |
| name | VARCHAR(255) | Nome da tag | - |
 
### 7. `languages`
 
Armazena os idiomas suportados pelos jogos.
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| id | INT | Identificador único do idioma | PRIMARY KEY |
| name | VARCHAR(255) | Nome do idioma | - |
 
### 8. `media`
 
Armazena mídias relacionadas aos jogos (screenshots, vídeos, etc.).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | FOREIGN KEY (games.app_id) |
| media_type | VARCHAR(50) | Tipo de mídia (screenshot, vídeo, etc.) | - |
| url | TEXT | URL da mídia | - |
| is_primary | BOOLEAN | Indica se é a mídia principal | - |
| order_index | INT | Ordem de exibição | - |
 
## Tabelas de Relacionamento
 
### 1. `game_developers`
 
Associa jogos aos seus desenvolvedores (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| developer_id | INT | Identificador do desenvolvedor | PRIMARY KEY, FOREIGN KEY (developers.id) |
 
### 2. `game_publishers`
 
Associa jogos às suas editoras (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| publisher_id | INT | Identificador da editora | PRIMARY KEY, FOREIGN KEY (publishers.id) |
 
### 3. `game_genres`
 
Associa jogos aos seus gêneros (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| genre_id | INT | Identificador do gênero | PRIMARY KEY, FOREIGN KEY (genres.id) |
| is_primary | BOOLEAN | Indica se é o gênero principal | - |
 
### 4. `game_tags`
 
Associa jogos às suas tags (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| tag_id | INT | Identificador da tag | PRIMARY KEY, FOREIGN KEY (tags.id) |
| votes | INT | Número de votos que a tag recebeu | - |
 
### 5. `game_categories`
 
Associa jogos às suas categorias (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| category_id | INT | Identificador da categoria | PRIMARY KEY, FOREIGN KEY (categories.id) |
 
### 6. `game_full_audio_languages`
 
Associa jogos aos idiomas com suporte completo de áudio (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| language_id | INT | Identificador do idioma | PRIMARY KEY, FOREIGN KEY (languages.id) |
 
### 7. `game_supported_languages`
 
Associa jogos aos idiomas suportados e detalhes de suporte (relação N:N).
 
| Coluna | Tipo | Descrição | Restrições |
|--------|------|-----------|------------|
| game_id | INT | Identificador do jogo | PRIMARY KEY, FOREIGN KEY (games.app_id) |
| language_id | INT | Identificador do idioma | PRIMARY KEY, FOREIGN KEY (languages.id) |
| interface_support | BOOLEAN | Indica se a interface suporta o idioma | - |
| subtitles_support | BOOLEAN | Indica se há suporte a legendas no idioma | - |