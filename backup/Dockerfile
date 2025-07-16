FROM ubuntu:latest

WORKDIR /var/lib/postgresql

ENV TZ=America/Bahia
ENV PGBACKREST_CONFIG="/var/lib/postgresql/pgbackrest.conf"

RUN groupadd -g 999 postgres && \
    useradd -u 999 -g 999 -d /var/lib/postgresql -s /bin/bash postgres && \
    mkdir -p /var/lib/postgresql/.ssh && \
    chown -R postgres:postgres /var/lib/postgresql

RUN mkdir -p /var/run/sshd /var/lib/postgresql/log /var/lib/pgbackrest /tmp/pgbackrest
RUN apt-get update && apt-get install -y curl gnupg lsb-release && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/pg.gpg && \
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update && \
    apt-get install -y \
    postgresql-client-10 \
    postgresql-client-11 \
    postgresql-client-12 \
    postgresql-client-13 \
    postgresql-client-14 \
    postgresql-client-15 \
    postgresql-client-16 \
    postgresql-client-17 \
    pgbackrest openssh-server gosu nano tzdata cron sudo netcat-openbsd

# Configura SSH sem senha para o pgbackrest
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
    # && cat /var/lib/postgresql/.ssh/id_ed25519.pub > /var/lib/postgresql/.ssh/authorized_keys

# Configura o SSH para aceitar conexões sem confirmação
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

# Script para gerar configuração do pgBackRest
COPY entrypoint-pgbackrest.sh /var/lib/postgresql/entrypoint-pgbackrest.sh
RUN chmod +x /var/lib/postgresql/entrypoint-pgbackrest.sh

# Entrypoint Custom
COPY entrypoint-custom.sh /var/lib/postgresql/entrypoint-custom.sh
RUN chmod +x /var/lib/postgresql/entrypoint-custom.sh

# Cria diretório para chaves SSH
RUN mkdir -p /var/lib/postgresql/.ssh && chmod 700 /var/lib/postgresql/.ssh

RUN chown -R postgres:postgres /var/lib/postgresql && \
    chown -R postgres:postgres /var/lib/pgbackrest && \
    chown -R postgres:postgres /tmp/pgbackrest

USER postgres

ENTRYPOINT [ "/bin/bash", "/var/lib/postgresql/entrypoint-custom.sh" ]