#!/bin/bash
set -e

# Gerar configuração do pgBackRest
/var/lib/postgresql/entrypoint-pgbackrest.sh

# Iniciar o SSH primeiro
sudo service ssh start

# Aguardar SSH estar pronto
sleep 5

# Aguardar que o container postgres esteja disponível
echo "Aguardando container postgres ficar disponível..."
while ! nc -z postgres 22; do
    sleep 2
done
echo "Container postgres disponível!"

# Configurar chaves SSH conhecidas automaticamente
echo "Configurando chaves SSH conhecidas..."
ssh-keyscan -H postgres >> /var/lib/postgresql/.ssh/known_hosts 2>/dev/null || echo "Aviso: Não foi possível adicionar chave SSH do postgres"

# Criar configuração SSH
cat > /var/lib/postgresql/.ssh/config <<EOF
Host postgres
  HostName postgres
  User postgres
  IdentityFile /var/lib/postgresql/.ssh/id_ed25519
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null

EOF
chmod 600 /var/lib/postgresql/.ssh/config

# Iniciar o Cron
sudo service cron start

# Garantir permissoes
sudo chown -R postgres:postgres /var/lib/postgresql
sudo chown -R postgres:postgres /var/lib/pgbackrest
sudo chown -R postgres:postgres /tmp/pgbackrest

# Manter o container rodando
tail -f /dev/null

# Configura o pgbackrest
sudo -u postgres pgbackrest --stanza=postgres stanza-create
sudo -u postgres pgbackrest --stanza=postgres check
sudo -u postgres pgbackrest --stanza=postgres --type=full backup