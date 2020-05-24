FROM ubuntu:20.04
# apt installs tzdata, will drop into interactive time zone configuratin without this env var
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get --yes update \
    && apt-get --yes install curl gpg smbnetfs bindfs \
    && rm -rf /var/lib/apt/lists/*

ENV TINI_VERSION=v0.19.0
RUN    curl -L -o /tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
    && curl -L -o /tini.asc https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc \
    && gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && gpg --batch --verify /tini.asc /tini \
    && chmod +x /tini

COPY etc/fuse.conf /etc/fuse.conf
COPY etc/smbnetfs.conf /etc/smbnetfs.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]
