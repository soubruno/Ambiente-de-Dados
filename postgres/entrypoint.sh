cat > /var/lib/postgresql/pgbackrest.conf <<EOF
[global]
repo1-path=/var/lib/pgbackrest
repo1-host=backup
repo1-host-user=postgres
repo1-retention-full=5
log-level-console=info
log-level-file=debug
log-path=/var/lib/postgresql/log
compress-level=3
start-fast=y
archive-async=y

[postgres]
pg1-path=/var/lib/postgresql/data/pgdata
pg1-port=5432
pg1-user=postgres
pg1-database=steam_games
EOF