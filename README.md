# Ambiente de Dados Automatizado
Neste projeto foi implementado um ambiente de dados a partir de uma base monolítica da plataforma Steam, transformando-a em um banco de dados relacional normalizado no PostgreSQL.

Em sua estrutura é possível contemplar:

- PostgreSQL 17 com suporte a SSH
- Servidor de backup em Ubuntu com **pgBackRest**
- Exportador de métricas via **postgres_exporter**
- Monitoramento com **Prometheus**
- Dashboard via **Grafana**
- Analisador de logs com **PgBadger**
- ETL via **Airflow + dbt**
- EL com **PGLoader**
- PostgreSQL 17 servindo como DW
- Visualização de dados via **Apache Superset**

> O projeto utiliza **Docker Compose** para facilitar o provisionamento e gerenciamento dos serviços.

---

## 📜 Pré-requisitos

### <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" height="25" alt="docker logo"  /> Docker e Docker Compose

[Site oficial do Docker Desktop para Windows](https://docs.docker.com/desktop/setup/install/windows-install/)

### 📦 Git LFS

Este projeto utiliza Git Large File Storage (LFS) para gerenciar arquivos grandes.<br>
Os seguintes arquivos são rastreados com Git LFS:
- `data/games.csv` (207 MB)
- `output/games.csv` (100 MB)
- `output/media.csv` (93 MB)
  
Instale o Git LFS
```bash
git lfs install
```

## 🚀 Como usar o Ambiente

### 1. Clonar o repositório
```bash
git clone <URL_DO_REPOSITORIO>
```
### 2. Configurar as variáveis de ambiente
Crie um arquivo `.env` com as variaveis necessárias no .env.example:
```bash
cp .env.example .env
```
### 3. Subir os serviços do docker com Docker Compose
```bash
docker compose up -d 
```

# 📄 Documentação

**📚 [Leia a documentação de modelagem e indexação em DOCUMENTATION.md](./docs/MODELAGEM.md)**

A documentação detalha:
- ✅ Análise comparativa entre arquivo original e estrutura normalizada
- ✅ Justificativas técnicas para cada melhoria implementada
- ✅ Estratégia completa de indexação com impactos de performance
- ✅ Migração para pgloader com configuração otimizada

**📚 [Leia a documentação dos comandos de backup em BACKUP_COMMANDS.md](./docs/COMANDOS_BACKUP.md)**

A documentação de backup inclui:
- ✅ Comandos para criação, restauração e manutenção de backups com pgBackRest
- ✅ Estratégias de monitoramento e logs

**📚 [Leia o dicionário de dados em DICIONARIO_DE_DADOS.md](./docs/DICIONARIO_DE_DADOS.md)**

O dicionário de dados contém:
- ✅ Estrutura detalhada do banco de dados normalizado
- ✅ Descrições de tabelas, colunas e relacionamentos

**📚 [Veja exemplo de gráficos criados com Apache Superset](./superset/README.md)**

O Readme do Superset inclui:
- ✅ Exemplo de consultas SQL para visualização de dados
- ✅ Passo a passo para iniciar o Apache Superset
- ✅ Captura do Dashboard de visualização de dados criado para análise do Data Warehouse
  
**📚 [Veja como acompanhar o monitoramento](./docs/SETUP_MONITORAMENTO.md)**

A documentação de monitoramento possui:
- ✅ As URLs de acesso para cada ferramenta de monitoramento
- ✅ Expôe métricas que podem ser analisadas 
- ✅ Exemplo de query usada para análise
