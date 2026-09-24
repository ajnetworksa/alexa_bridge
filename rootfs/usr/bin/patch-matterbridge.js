const fs = require('fs');

console.log('[patch] Running Matterbridge compatibility patches...');

// 1. Patch @matterbridge/core platform type/brand check
const corePlatformFiles = [
  '/app/node_modules/@matterbridge/core/dist/matterbridgePlatform.js',
  '/app/node_modules/@matterbridge/core/dist/matterbridgeDynamicPlatform.js',
  '/data/Matterbridge/node_modules/@matterbridge/core/dist/matterbridgePlatform.js',
  '/data/Matterbridge/node_modules/@matterbridge/core/dist/matterbridgeDynamicPlatform.js'
];

for (const file of corePlatformFiles) {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    content = content.replace(
      /export function isMatterbridgePlatform\(value\) \{[\s\S]*?\n\}/,
      'export function isMatterbridgePlatform(value) {\n    return Boolean(value && typeof value === "object");\n}'
    );
    content = content.replace(
      /export function isMatterbridgeDynamicPlatform\(value\) \{[\s\S]*?\n\}/,
      'export function isMatterbridgeDynamicPlatform(value) {\n    return Boolean(value && typeof value === "object");\n}'
    );
    fs.writeFileSync(file, content);
    console.log('[patch] Patched platform check in', file);
  }
}

// 2. Patch homeAssistant.js to automatically sanitize host URLs (stripping trailing slashes and handling http:// vs ws://)
const haFiles = [
  '/app/node_modules/matterbridge-hass/dist/homeAssistant.js',
  '/data/Matterbridge/matterbridge-hass/dist/homeAssistant.js',
  '/usr/local/lib/node_modules/matterbridge-hass/dist/homeAssistant.js'
];

for (const file of haFiles) {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    content = content.replace(
      'this.wsUrl = url;',
      'this.wsUrl = (url || "").trim().replace(/^http:\\/\\//, "ws://").replace(/^https:\\/\\//, "wss://").replace(/\\/+$/, "").replace(/\\/api\\/websocket\\/?$/, "");'
    );
    fs.writeFileSync(file, content);
    console.log('[patch] Patched WebSocket URL sanitizer in', file);
  }
}

// 3. Sanitize existing /data/.matterbridge/matterbridge-hass.json if present
const configJson = '/data/.matterbridge/matterbridge-hass.json';
if (fs.existsSync(configJson)) {
  try {
    let config = JSON.parse(fs.readFileSync(configJson, 'utf8'));
    if (config.host && typeof config.host === 'string') {
      const sanitized = config.host.trim().replace(/^http:\/\//, 'ws://').replace(/^https:\/\//, 'wss://').replace(/\/+$/, '').replace(/\/api\/websocket\/?$/, '');
      if (sanitized !== config.host) {
        config.host = sanitized;
        fs.writeFileSync(configJson, JSON.stringify(config, null, 2));
        console.log('[patch] Sanitized host in', configJson, '->', sanitized);
      }
    }
  } catch (err) {
    console.error('[patch] Error reading/writing', configJson, err.message);
  }
}

console.log('[patch] Compatibility patches applied successfully ✓');
