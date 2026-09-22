#!/usr/bin/env bash
##
## setup-matterbridge.sh
## Generates Matterbridge config from env vars set by run.sh
##

set -euo pipefail

PROFILE_DIR="/data/matterbridge/AlexaBridge"
CONFIG_FILE="${PROFILE_DIR}/matterbridge.json"
PLUGIN_CONFIG_FILE="${PROFILE_DIR}/matterbridge-hass.config.json"

mkdir -p "${PROFILE_DIR}"

# Build excluded prefixes JSON array from options.json
EXCLUDED_PREFIXES_JSON=$(jq -c \
    '.excluded_entity_prefixes // ["automation.","scene.","script.","group.","device_tracker.","person.","zone.","timer."]' \
    /data/options.json 2>/dev/null || \
    echo '["automation.","scene.","script.","group.","device_tracker.","person.","zone.","timer."]')

# Unique serial based on hostname
SERIAL="AMB-$(hostname | md5sum | cut -c1-8 2>/dev/null || echo 'default')"

echo "[setup] Writing Matterbridge config → ${CONFIG_FILE}"

cat > "${CONFIG_FILE}" << EOF
{
  "name": "Matterbridge",
  "username": "Alexa-HA-Bridge",
  "port": ${MATTER_PORT:-5540},
  "passcode": 20202021,
  "discriminator": 3840,
  "vendorId": 65521,
  "vendorName": "AJ Network Solutions",
  "productId": 32769,
  "productName": "Alexa Matter Bridge",
  "serialNumber": "${SERIAL}",
  "logLevel": "${LOG_LEVEL:-info}",
  "matterLogLevel": "warn"
}
EOF

echo "[setup] Writing matterbridge-hass plugin config → ${PLUGIN_CONFIG_FILE}"

cat > "${PLUGIN_CONFIG_FILE}" << EOF
{
  "host": "http://${HA_HOST:-homeassistant}:${HA_PORT:-8123}",
  "token": "${SUPERVISOR_TOKEN:-}",
  "reconnectInterval": 30000,
  "requestTimeout": 60000,
  "exposeLabel": "${EXPOSE_LABEL:-alexa}",
  "excludedPrefixes": ${EXCLUDED_PREFIXES_JSON},
  "deviceTypes": {
    "light": true,
    "switch": true,
    "binary_sensor": true,
    "sensor": true,
    "cover": true,
    "climate": true,
    "fan": true,
    "lock": true,
    "media_player": false,
    "camera": false
  }
}
EOF

echo "[setup] Configuration written ✓"
