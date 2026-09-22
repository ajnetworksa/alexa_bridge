ARG BUILD_FROM=""
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    nodejs \
    npm \
    python3 \
    avahi \
    avahi-compat-libdns_sd \
    dbus \
    tzdata \
    curl \
    jq \
    bash

RUN node --version && npm --version

WORKDIR /app
COPY package.json /app/package.json
RUN npm install && npm cache clean --force

COPY run.sh /run.sh
COPY rootfs/ /

RUN chmod +x /run.sh && \
    chmod +x /usr/bin/setup-matterbridge.sh && \
    chmod +x /usr/bin/backup-commissioning.sh && \
    chmod +x /usr/bin/restore-commissioning.sh && \
    chmod +x /usr/bin/entity-manager.sh

EXPOSE 5540/tcp
EXPOSE 5540/udp
EXPOSE 8098/tcp

CMD ["/run.sh"]
