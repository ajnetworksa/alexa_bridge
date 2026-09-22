##
## alexa-matter-bridge/Dockerfile
##
## Builds on the official HA base image (Alpine-based).
## Installs Node.js for Matterbridge, avahi for mDNS Matter discovery,
## and Python3 (stdlib only) for the status UI.
##

ARG BUILD_FROM=""
FROM ${BUILD_FROM}

# ──────────────────────────────────────────────
# System dependencies (Alpine package names)
# Note: libnss-mdns is Debian-only — avahi handles mDNS on Alpine
# Note: py3-pip not needed — status UI uses Python stdlib only
# ──────────────────────────────────────────────
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

# ──────────────────────────────────────────────
# Install Matterbridge + Home Assistant plugin
# ──────────────────────────────────────────────
WORKDIR /app

COPY package.json /app/package.json

RUN npm install && \
    npm cache clean --force

# (bashio removed — using jq + /data/options.json instead)

# ──────────────────────────────────────────────
# Copy add-on files
# ──────────────────────────────────────────────
COPY run.sh /run.sh
COPY rootfs/ /

RUN chmod +x /run.sh && \
    chmod +x /usr/bin/setup-matterbridge.sh && \
    chmod +x /usr/bin/backup-commissioning.sh && \
    chmod +x /usr/bin/restore-commissioning.sh && \
    chmod +x /usr/bin/entity-manager.sh

# ──────────────────────────────────────────────
# Expose ports
# ──────────────────────────────────────────────
EXPOSE 5540/tcp
EXPOSE 5540/udp
EXPOSE 8098/tcp

CMD ["/run.sh"]
