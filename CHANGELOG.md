# Changelog

## 1.1.0
**Fixes**
- The plugin config was written to `/data/matterbridge/AlexaBridge/`, which Matterbridge never reads, with
  option names the plugin doesn't know (`exposeLabel`, `excludedPrefixes`, `deviceTypes`). The plugin started with
  no token and no filter. It is now written to `/data/.matterbridge/matterbridge-hass.config.json` with the real keys
  (`filterByLabel`, `entityBlackList`).
- Connect through the Supervisor proxy (`ws://supervisor/core/websocket`) with the add-on token. The hostname
  `homeassistant` doesn't resolve for host-network add-ons, and the add-on token isn't valid on port 8123.
- Expose / hide never worked: `entity-manager.sh` used an unset variable (crashed under `set -u`) and a REST endpoint
  that doesn't exist. Labels are now set through the entity registry WebSocket API.
- The exposed-devices list was always empty (labels aren't state attributes).
- The page used absolute `/api/...` URLs, which fail behind ingress.
- The backup archived the unused config folder instead of the Matter pairing. It now saves `matterstorage` +
  `storage` to `/share/alexa_bridge/`, which survives uninstalling the add-on.
- The status UI was reachable by anyone on the LAN on port 8098 without login. It now answers ingress only.

**Changes**
- Status UI moved to port 8095 (8098 is used by AJ Netweb CCTV Studio on the host network).
- Pinned stable releases: Matterbridge 3.10.14 + matterbridge-hass 1.5.0 (was a dev build), installed globally so
  there is a single copy of the Matterbridge core (removes the need for the platform brand-check patch).
- Compatibility patch is applied at build time and fails the build if upstream code changes.
- Removed avahi/dbus (matter.js has its own mDNS) and `build.yaml` restored with pinned base images.

**New**
- QR code and manual pairing code shown in the add-on page, pairing status.
- Device picker with search, room grouping, "expose recommended", warnings for names over 32 characters.
- One-click restart, backup now, restore, and log viewer.
