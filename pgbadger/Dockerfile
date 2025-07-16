FROM debian:11.7-slim

ARG VERSION=12.1

WORKDIR /var/lib/pgbadger

RUN mkdir -m 777 -p /var/lib/pgbadger/log; \
    mkdir -m 777 -p /var/lib/pgbadger/outdir;

RUN apt-get update -y && \
    apt-get install -y \
    wget \
    libjson-xs-perl \
    make \
    perl \
    python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/darold/pgbadger/archive/refs/tags/v${VERSION}.tar.gz; \
    tar xzf v${VERSION}.tar.gz; \
    rm v${VERSION}.tar.gz; \
    cd pgbadger-${VERSION}/; \
    perl Makefile.PL INSTALLDIRS=vendor; \
    make && make install;

COPY entrypoint-pgbadger.sh /usr/local/bin/entrypoint-pgbadger.sh
RUN chmod +x /usr/local/bin/entrypoint-pgbadger.sh

EXPOSE 5000

ENTRYPOINT ["/usr/local/bin/entrypoint-pgbadger.sh"]
