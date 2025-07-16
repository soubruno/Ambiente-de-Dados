FROM apache/airflow:3.0.2

USER root

# Instalar dependências do sistema necessárias para DBT e outras ferramentas
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

# Copiar e instalar requirements do Python
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Criar diretórios necessários
RUN mkdir -p /opt/airflow/dbt /opt/airflow/dags /opt/airflow/logs /opt/airflow/plugins /opt/airflow/config

# Copiar configurações do DBT
COPY dbt_profiles.yml /opt/airflow/.dbt/profiles.yml