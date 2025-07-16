FROM postgres:17-bullseye
WORKDIR /var/lib/postgresql

ENV PGDATA="/var/lib/postgresql/data/pgdata"
ENV POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256"
ENV TZ="America/Bahia"
ENV PGTZ="America/Bahia"
ENV PGPORT="5432"
ENV PGBACKREST_CONFIG="/var/lib/postgresql/pgbackrest.conf"

RUN mkdir -p /var/run/sshd /var/lib/postgresql/log /var/lib/pgbackrest /tmp/pgbackrest
RUN touch /var/lib/postgresql/log/postgresql-postgres.log && chmod 777 -R /var/lib/postgresql/log
RUN apt-get update -y && apt-get install -y curl gnupg lsb-release sudo openssh-server pgbackrest gosu cron nano tzdata && rm -rf /var/lib/apt/lists/*

# Confs PGBackRest
COPY entrypoint.sh /docker-entrypoint-initdb.d/00-pgbackrest.sh
RUN chmod +x /docker-entrypoint-initdb.d/00-pgbackrest.sh

#Inicialização PGBackRest - Será executado uma unica vez, assim que o container for levantado pela primeira vez
RUN cat > /docker-entrypoint-initdb.d/pgbackrest-init.sh <<EOF
#!/bin/bash
set -e

# Configura o pgBackRest após a inicialização do PostgreSQL
pgbackrest --stanza=postgres stanza-create
pgbackrest --stanza=postgres check

EOF
RUN chmod +x /docker-entrypoint-initdb.d/pgbackrest-init.sh

RUN mkdir -p /var/lib/postgresql/.ssh \
    && chown -R postgres:postgres /var/lib/postgresql \
    && usermod -aG sudo postgres \
    && passwd -d postgres \
    && echo "postgres ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/postgres \
    && chmod 0440 /etc/sudoers.d/postgres \
    && gosu postgres ssh-keygen -t ed25519 -f /var/lib/postgresql/.ssh/id_ed25519 -N '' -q \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chmod 700 /var/lib/postgresql/.ssh \
    && chmod 600 /var/lib/postgresql/.ssh/* 
    # && cat /var/lib/postgresql/.ssh/id_rsa.pub > /var/lib/postgresql/.ssh/authorized_keys 

# Confs SSH
RUN passwd -d root && \
    echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config && \
    echo "Match User postgres" >> /etc/ssh/sshd_config && \
    echo "    PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "    PermitEmptyPasswords no" >> /etc/ssh/sshd_config && \
    echo "    AuthenticationMethods publickey" >> /etc/ssh/sshd_config && \
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?\(PubkeyAuthentication\).*$/\1 yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?\(AuthorizedKeysFile\).*$/\1 .ssh\/authorized_keys/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?\(StrictModes\).*$/\1 no/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# Cria diretório para chaves SSH
RUN mkdir -p /var/lib/postgresql/.ssh && chmod 700 /var/lib/postgresql/.ssh

# Arquivo SSH config será criado em tempo de execução no entrypoint

# Crontab agendamento
# Realizar backup a cada 50 minutos

RUN cat > /var/lib/postgresql/crontab-agendar <<EOF
*/50 * * * * echo "Realizando backup" #### && pgbackrest backup && echo "Backup realizado"
EOF

# Entrypoint Custom
COPY docker-entrypoint-custom.sh /usr/local/bin/docker-entrypoint-custom.sh

# RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh && chmod 0644 /var/lib/postgresql/crontab-agendar
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh && chmod 0644 /var/lib/postgresql/crontab-agendar && chown -R postgres:postgres /var/lib/postgresql

USER root

ENTRYPOINT [ "/bin/bash", "/usr/local/bin/docker-entrypoint-custom.sh" ]