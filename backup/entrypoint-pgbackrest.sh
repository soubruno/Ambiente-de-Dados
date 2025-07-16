#!/bin/bash
set -e

# Gerar configuração do pgBackRest usando variáveis de ambiente
cat > /var/lib/postgresql/pgbackrest.conf <<EOF
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=5
log-level-console=info
log-level-file=debug
log-path=/var/log/pgbackrest
start-fast=y

[postgres]
pg1-path=/var/lib/postgresql/data/pgdata
pg1-host=postgres
pg1-port=5432
pg1-user=postgres
pg1-database=steam_games

EOF

chmod 640 /var/lib/postgresql/pgbackrest.conf
chown postgres:postgres /var/lib/postgresql/pgbackrest.conf