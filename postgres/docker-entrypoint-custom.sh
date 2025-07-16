# Garante que o diretório e o arquivo authorized_keys existem e são do usuário postgres
sudo -u postgres mkdir -p /var/lib/postgresql/.ssh
sudo -u postgres touch /var/lib/postgresql/.ssh/authorized_keys
sudo -u postgres chmod 700 /var/lib/postgresql/.ssh
PUB_KEY=$(cat /var/lib/postgresql/.ssh/id_ed25519.pub)
sudo -u postgres grep -qxF "$PUB_KEY" /var/lib/postgresql/.ssh/authorized_keys || echo "$PUB_KEY" | sudo -u postgres tee -a /var/lib/postgresql/.ssh/authorized_keys > /dev/null
sudo -u postgres chmod 600 /var/lib/postgresql/.ssh/authorized_keys
sudo -u postgres chown postgres:postgres /var/lib/postgresql/.ssh/authorized_keys
# Debug: mostra estado do .ssh antes do loop
echo "DEBUG: Conteúdo e permissões do .ssh"
ls -l /var/lib/postgresql/.ssh
cat /var/lib/postgresql/.ssh/authorized_keys || echo "(authorized_keys não existe)"
whoami
# Espera o SSH do backup estar disponível antes de qualquer operação dependente
until sudo -u postgres ssh -o StrictHostKeyChecking=no -i /var/lib/postgresql/.ssh/id_ed25519 postgres@backup 'echo SSH OK' 2>/dev/null; do
  echo "Aguardando SSH do backup ficar disponível..."
  sleep 2
done
#!/bin/bash
set -e


# Garantir arquivo de log
mkdir -p /var/lib/postgresql/log && touch /var/lib/postgresql/log/postgresql-postgres.log && chmod 777 -R /var/lib/postgresql/log

# Gera chave se não existir
if [ ! -f /var/lib/postgresql/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N '' -f /var/lib/postgresql/.ssh/id_ed25519
fi


# Permissões corretas
chmod 700 /var/lib/postgresql/.ssh
chmod 600 /var/lib/postgresql/.ssh/id_ed25519
chmod 600 /var/lib/postgresql/.ssh/id_ed25519.pub
chown -R postgres:postgres /var/lib/postgresql/.ssh

# Garante que a chave pública esteja no authorized_keys compartilhado, sem duplicatas
PUB_KEY=$(cat /var/lib/postgresql/.ssh/id_ed25519.pub)
grep -qxF "$PUB_KEY" /var/lib/postgresql/.ssh/authorized_keys || echo "$PUB_KEY" >> /var/lib/postgresql/.ssh/authorized_keys
chmod 600 /var/lib/postgresql/.ssh/authorized_keys
chown postgres:postgres /var/lib/postgresql/.ssh/authorized_keys

# Automatiza aceitação do fingerprint do host backup
ssh-keyscan -H backup >> /var/lib/postgresql/.ssh/known_hosts 2>/dev/null

# Aguardar o container backup estar pronto
sleep 20

# Criar configuração SSH com variáveis de ambiente
cat > /var/lib/postgresql/.ssh/config <<EOF
Host backup
  HostName backup
  User postgres
  IdentityFile /var/lib/postgresql/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOF
chmod 600 /var/lib/postgresql/.ssh/config && chown postgres:postgres /var/lib/postgresql/.ssh/config

## Copiar chave pública para o container backup (sempre como usuário postgres)
sudo -u postgres ssh -o StrictHostKeyChecking=no postgres@backup "mkdir -p /var/lib/postgresql/.ssh && touch /var/lib/postgresql/.ssh/authorized_keys && chmod 700 /var/lib/postgresql/.ssh && chmod 600 /var/lib/postgresql/.ssh/authorized_keys && chown -R postgres:postgres /var/lib/postgresql/.ssh"
cat /var/lib/postgresql/.ssh/id_ed25519.pub | sudo -u postgres ssh -o StrictHostKeyChecking=no postgres@backup "grep -qxF '$(cat)' /var/lib/postgresql/.ssh/authorized_keys || echo '$(cat)' >> /var/lib/postgresql/.ssh/authorized_keys"

# Iniciar cron
cron

# Agendar Cron
crontab -u postgres /var/lib/postgresql/crontab-agendar

# Iniciar ssh server
/etc/init.d/ssh start

# Iniciar PostgreSQL
/usr/local/bin/docker-entrypoint.sh postgres \
-c logging_collector=on \
-c log_directory='/var/lib/postgresql/log' \
-c log_filename='postgresql-postgres.log' \
-c log_statement='all' \
-c log_line_prefix='%t [%p]: [%l-1] ' \
-c log_destination='stderr' \
-c log_min_duration_statement=0 \
-c log_connections=on \
-c log_disconnections=on \
-c archive_mode=on \
-c shared_preload_libraries='pg_stat_statements' \
-c archive_command='pgbackrest --stanza=postgres archive-push %p' &

# Garantir permissoes
chown -R postgres:postgres /var/lib/postgresql
chown -R postgres:postgres /var/lib/pgbackrest
chown -R postgres:postgres /tmp/pgbackrest

# Monitorar logs
tail -f /var/lib/postgresql/log/postgresql-postgres.log