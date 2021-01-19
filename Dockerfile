FROM ubuntu:18.04

LABEL maintainer.0="Isuranga Perera"

RUN useradd -r bitcoin \
  && apt-get update -y \
  && apt-get install -y curl gnupg gosu python3-pip\
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV BITCOIN_VERSION=0.18.1
ENV BITCOIN_DATA=/mnt/data/bitcoin

RUN set -ex \
  && curl -SLO https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz \
  && tar -xzf *.tar.gz -C /opt \
  && rm *.tar.gz

COPY scripts/docker-entrypoint.sh /entrypoint.sh
COPY scripts/bootstrap.sh /bootstrap.sh
COPY scripts/start_bitcoind.sh /start_bitcoind.sh
COPY scripts/bitcoin_to_rabbitmq_exporter.py /bitcoin_to_rabbitmq_exporter.py

RUN pip3 install bitcoin-etl pika

RUN chmod 755 /entrypoint.sh
RUN chmod 755 /bootstrap.sh
RUN chmod 755 /start_bitcoind.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ./bootstrap.sh