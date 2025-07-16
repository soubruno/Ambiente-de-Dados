# Steam Games Database - Documentação de Modelagem (Normalização, Indexação, Programação)

Este documento detalha as melhorias de modelagem de dados implementadas no Steam Games Database, transformando um arquivo CSV monolítico em um banco de dados relacional normalizado.

## 🎯 Problemas Identificados no Arquivo Original (games.csv)

### 1. **Violação da Primeira Forma Normal (1FN)**
- **Problema**: Campos com múltiplos valores separados por vírgulas/ponto-e-vírgula
- **Exemplos**: 
  - `developers`: "Valve,Hidden Path Entertainment"
  - `categories`: "Multi-player,Online Co-op,Steam Achievements"
  - `genres`: "Action,Free to Play,Massively Multiplayer"
  - `supported_languages`: "English,French,Italian,German"

### 2. **Redundância de Dados**
- **Problema**: Repetição desnecessária de informações
- **Exemplos**:
  - Nome do desenvolvedor "Valve" repetido em milhares de registros
  - Gêneros como "Action" duplicados em múltiplos jogos
  - Idiomas suportados repetidos constantemente

### 3. **Inconsistência de Dados**
- **Problema**: Variações na escrita de valores similares
- **Exemplos**:
  - "English" vs "english" vs "ENGLISH"
  - "Portuguese - Brazil" vs "Portuguese" vs "português"
  - "Single-player" vs "Singleplayer" vs "Single Player"

### 4. **Falta de Integridade Referencial**
- **Problema**: Impossibilidade de garantir consistência entre relacionamentos
- **Impactos**: Desenvolvedores inexistentes, gêneros inválidos, dados órfãos

### 5. **Campos com Tipos Inadequados**
- **Problema**: Uso de TEXT para dados que deveriam ser tipados
- **Exemplos**:
  - Preços como strings: "19.99" em vez de DECIMAL
  - Datas como strings: "Oct 21, 2008" em vez de DATE
  - Ranges de owners: "0 - 20000" em vez de campos numéricos separados

---

## 🛠️ Soluções Implementadas na Modelagem

### 1. **Normalização Completa até a Terceira Forma Normal (3FN)**

#### **Tabelas de Entidades Principais**
```sql
-- Desenvolvedores normalizados
CREATE TABLE developers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(500) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Publishers normalizados  
CREATE TABLE publishers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(500) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Categorias normalizadas
CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Justificativa**: Elimina redundância e garante integridade referencial.

#### **Tabelas de Relacionamento (Muitos-para-Muitos)**
```sql
-- Relacionamento Jogos ↔ Desenvolvedores
CREATE TABLE game_developers (
    game_id INTEGER REFERENCES games(app_id) ON DELETE CASCADE,
    developer_id INTEGER REFERENCES developers(id) ON DELETE CASCADE,
    role VARCHAR(100) DEFAULT 'developer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (game_id, developer_id)
);

-- Relacionamento Jogos ↔ Gêneros
CREATE TABLE game_genres (
    game_id INTEGER REFERENCES games(app_id) ON DELETE CASCADE,
    genre_id INTEGER REFERENCES genres(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (game_id, genre_id)
);
```

**Justificativa**: Resolve relacionamentos muitos-para-muitos de forma adequada.

### 2. **Melhorias na Tabela Principal (games)**

#### **Separação de Campos de Owners**
```sql
-- Antes: estimated_owners = "0 - 20000" (TEXT)
-- Depois:
estimated_owners_min INTEGER,
estimated_owners_max INTEGER,
```

#### **Normalização de Preços**
```sql
-- Antes: price = "19.99" (TEXT)
-- Depois:
current_price DECIMAL(10,2),
currency_id INTEGER REFERENCES currencies(id) DEFAULT 1,
```

#### **Tipagem Adequada de Datas**
```sql
-- Antes: release_date = "Oct 21, 2008" (TEXT)
-- Depois:
release_date DATE,
```

---

## 📊 Estratégia de Indexação Implementada

### 1. **Índices para Tabelas de Entidades Principais**

```sql
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_developers_name ON developers(name);
CREATE INDEX idx_publishers_name ON publishers(name);
CREATE INDEX idx_genres_name ON genres(name);
CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_languages_name ON languages(name);
```

**Justificativas:**
- **Consultas**: Busca textual por nomes (ex: `WHERE developers.name = 'Valve'`)
- **Performance**: Evita full table scan em milhões de registros
- **Integridade**: Suporte eficiente para constraints UNIQUE

### 2. **Índices para Tabela Games - Campos de Busca Frequente**

```sql
CREATE INDEX idx_games_name ON games(name);
```
**Justificativas:**
- **Consultas**: Busca de jogos por nome (consulta mais comum em sistemas de jogos)
- **Performance**: Essencial para autocomplete e busca textual
- **Utilidade**: Suporte para operações LIKE e busca parcial

```sql
CREATE INDEX idx_games_release_date ON games(release_date);
```
**Justificativas:**
- **Consultas**: Filtros temporais (`WHERE release_date BETWEEN '2020-01-01' AND '2020-12-31'`)
- **Performance**: Otimiza ordenação cronológica e análises de tendências
- **Utilidade**: Suporte para relatórios de lançamentos por período

```sql
CREATE INDEX idx_games_current_price ON games(current_price);
```
**Justificativas:**
- **Consultas**: Filtros por faixa de preço (`WHERE current_price BETWEEN 10 AND 50`)
- **Performance**: Otimiza ordenação por preço (crescente/decrescente)
- **Utilidade**: Essencial para funcionalidades de e-commerce

### 3. **Índices para Avaliações e Qualidade**

```sql
CREATE INDEX idx_games_metacritic_score ON games(metacritic_score);
CREATE INDEX idx_games_user_score ON games(user_score);
```
**Justificativas:**
- **Consultas**: Filtros por qualidade (`WHERE metacritic_score >= 80`)
- **Performance**: Otimiza ordenação por rating para "top games"
- **Utilidade**: Suporte para sistemas de recomendação

### 4. **Índices para Classificação e Status**

```sql
CREATE INDEX idx_games_is_free ON games(is_free);
CREATE INDEX idx_games_status ON games(game_status);
CREATE INDEX idx_games_required_age ON games(required_age);
```
**Justificativas:**
- **Consultas**: Filtros categóricos frequentes (`WHERE is_free = true`)
- **Performance**: Valores booleanos e enums têm alta seletividade
- **Utilidade**: Essencial para controle parental e categorização

### 5. **Índices Compostos para Análises Complexas**

```sql
CREATE INDEX idx_games_estimated_owners ON games(estimated_owners_min, estimated_owners_max);
```
**Justificativas:**
- **Consultas**: Análises de popularidade em faixas específicas
- **Performance**: Otimiza queries de range em dois campos relacionados
- **Utilidade**: Suporte para métricas de sucesso comercial

```sql
CREATE INDEX idx_games_reviews ON games(positive_reviews, negative_reviews);
```
**Justificativas:**
- **Consultas**: Cálculo de rating geral (positive/(positive+negative))
- **Performance**: Evita scan completo para métricas de aprovação
- **Utilidade**: Essencial para algoritmos de ranking

### 6. **Índices para Relacionamentos - Chaves Estrangeiras**

```sql
CREATE INDEX idx_game_developers_developer ON game_developers(developer_id);
CREATE INDEX idx_game_publishers_publisher ON game_publishers(publisher_id);
CREATE INDEX idx_game_categories_category ON game_categories(category_id);
CREATE INDEX idx_game_genres_genre ON game_genres(genre_id);
CREATE INDEX idx_game_tags_tag ON game_tags(tag_id);
CREATE INDEX idx_game_languages_language ON game_full_audio_languages(language_id);
```
**Justificativas:**
- **Performance**: Acelera operações JOIN fundamentais
- **Consultas**: Busca de jogos por desenvolvedor, gênero, etc.
- **Integridade**: Suporte eficiente para foreign key constraints

### 7. **Índices para Funcionalidades Específicas**

```sql
CREATE INDEX idx_game_genres_primary ON game_genres(is_primary);
CREATE INDEX idx_game_genres_genre_primary ON game_genres(genre_id, is_primary);
```
**Justificativas:**
- **Consultas**: Diferenciação entre gênero principal e secundário
- **Performance**: Filtros específicos para categorização primária
- **Utilidade**: Suporte para algoritmos de classificação hierárquica

```sql
CREATE INDEX idx_game_tags_votes ON game_tags(votes DESC);
CREATE INDEX idx_game_tags_tag_votes ON game_tags(tag_id, votes DESC);
```
**Justificativas:**
- **Consultas**: Ordenação por popularidade das tags
- **Performance**: Otimiza queries de "top tags" e trending
- **Utilidade**: Essencial para sistemas de descoberta de conteúdo

### 8. **Índices para Suporte de Idiomas**

```sql
CREATE INDEX idx_game_supported_interface ON game_supported_languages(interface_support);
CREATE INDEX idx_game_supported_subtitles ON game_supported_languages(subtitles_support);
```
**Justificativas:**
- **Consultas**: Filtros específicos de localização
- **Performance**: Otimiza busca por suporte de idioma específico
- **Utilidade**: Essencial para mercados internacionais

### 9. **Índices para Gestão de Mídia**

```sql
CREATE INDEX idx_media_type ON media(media_type);
CREATE INDEX idx_media_primary ON media(is_primary);
CREATE INDEX idx_media_order ON media(game_id, order_index);
CREATE INDEX idx_media_type_primary ON media(media_type, is_primary);
```
**Justificativas:**
- **Consultas**: Separação eficiente entre screenshots, vídeos, etc.
- **Performance**: Otimiza carregamento de mídia principal (thumbnails)
- **Utilidade**: Suporte para ordenação correta na interface do usuário
- **Integridade**: Garante unicidade de mídia primária por tipo