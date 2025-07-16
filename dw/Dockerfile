FROM postgres:17

# Instalar dependências básicas
RUN apt-get update && apt-get install -y \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# Copiar apenas o schema SQL
COPY relacional.sql /docker-entrypoint-initdb.d/

# Expor porta padrão
EXPOSE 5432