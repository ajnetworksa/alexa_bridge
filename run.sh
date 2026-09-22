#!/usr/bin/env bash
##
## run.sh — Alexa Matter Bridge entrypoint
## Reads config from /data/options.json (HA standard, no bashio needed)
##

set -euo pipefail

echo "========================================"
echo "  Alexa Matter Bridge v1.0.0 Starting"
echo "========================================"

# ── Read options from /data/options.json ──────────────────────
# HA writes the add-on config options here automatically
OPTIONS="/data/options.json"

if [ -f "${OPTIONS}" ]; then
    MATTER_PORT=$(jq -r '.matter_port // 5540'           "${OPTIONS}")
    LOG_LEVEL=$(jq   -r '.log_level // "info"'           "${OPTIONS}")
    EXPOSE_LABEL=$(jq -r '.auto_expose_label // "alexa"' "${OPTIONS}")
    BACKUP_ENABLED=$(jq -r '.backup_commissioning // true' "${OPTIONS}")
else
    echo "[warn] /data/options.json not found — using defaults"
    MATTER_PORT=5540
    LOG_LEVEL="info"
    EXPOSE_LABEL="alexa"
    BACKUP_ENABLED=true
fi

echo "Matter port  : ${MATTER_PORT}"
echo "Log level    : ${LOG_LEVEL}"
echo "Expose label : ${EXPOSE_LABEL}"
echo "Backup       : ${BACKUP_ENABLED}"

# ── HA connection via Supervisor ───────────────────────────────
# SUPERVISOR_TOKEN is injected by HA when hassio_api: true
# The internal HA hostname inside the add-on network is 'homeassistant'
HA_HOST="homeassistant"
HA_PORT=8123

echo "HA endpoint  : http://${HA_HOST}:${HA_PORT}"

# Export for child scripts
export HA_HOST HA_PORT MATTER_PORT LOG_LEVEL EXPOSE_LABEL SUPERVISOR_TOKEN

# ── Start avahi mDNS daemon (Matter discovery) ─────────────────
echo "Starting avahi mDNS daemon..."
mkdir -p /var/run/avahi-daemon /run/dbus
dbus-daemon --system --nofork &
sleep 1
avahi-daemon --daemonize --no-chroot 2>/dev/null && \
    echo "avahi started ✓" || \
    echo "avahi failed to start (continuing without mDNS — WiFi Matter still works)"

# ── Restore commissioning backup if this is a fresh start ─────
if [ -f /data/commissioning_backup.tar.gz ] && \
   [ ! -d /data/matterbridge/AlexaBridge ]; then
    echo "Restoring commissioning backup..."
    /usr/bin/restore-commissioning.sh && \
        echo "Commissioning restored ✓" || \
        echo "Restore failed — fresh pairing required"
fi

# ── Generate Matterbridge config ───────────────────────────────
echo "Generating Matterbridge configuration..."
/usr/bin/setup-matterbridge.sh

# ── Commissioning auto-backup loop ────────────────────────────
if [ "${BACKUP_ENABLED}" = "true" ]; then
    echo "Auto-backup enabled (every 6h)"
    (
        while true; do
            sleep 21600
            /usr/bin/backup-commissioning.sh 2>/dev/null || true
        done
    ) &
fi

# ── Start the status UI (background) ──────────────────────────
echo "Starting status UI on port 8098..."
python3 /usr/share/alexa-bridge-ui/server.py \
    --host "0.0.0.0" \
    --port 8098 \
    --ha-host "${HA_HOST}" \
    --ha-port "${HA_PORT}" \
    --ha-token "${SUPERVISOR_TOKEN:-}" \
    --expose-label "${EXPOSE_LABEL}" \
    --data-dir "/data" &

UI_PID=$!
echo "Status UI PID: ${UI_PID} ✓"

# Give UI a moment to bind the port
sleep 2

# ── Start Matterbridge (foreground) ───────────────────────────
echo ""
echo "========================================"
echo "  Starting Matterbridge..."
echo "  Matter port : ${MATTER_PORT}"
echo "  UI          : http://homeassistant:8098"
echo "========================================"

exec node /app/node_modules/.bin/matterbridge \
    -bridge \
    -port "${MATTER_PORT}" \
    -logger "${LOG_LEVEL}"
