FROM apache/superset:latest


# Instalar dependências extras para o PostgreSQL
USER root
RUN pip install psycopg2-binary

# Usuário superset para operações
USER superset
