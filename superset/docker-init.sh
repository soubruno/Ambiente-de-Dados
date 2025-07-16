#!/bin/bash

# Inicializando o banco de dados do Superset
superset db upgrade

# Criar usuário admin se não existir
superset fab create-admin \
    --username admin \
    --firstname Superset \
    --lastname Admin \
    --email admin@superset.com \
    --password admin

# Configuração adicional
superset init

# Iniciar o servidor Superset
/usr/bin/run-server.sh
