const axios = require('axios');
const config = require('../config');

/**
 * Optional last-resort resolve tier: a paid third-party media API.
 * Disabled unless FALLBACK_API_URL and FALLBACK_API_KEY are configured.
 * Contract: POST {url} -> JSON body containing `mediaUrl` (or `videoUrl`).
 */
function isFallbackConfigured() {
  return Boolean(config.fallbackApiUrl && config.fallbackApiKey);
}

/**
 * @returns {Promise<{ok: true, videoUrl: string, thumbnailUrl: string|null, via: string}|null>}
 *          null when disabled, not found, or on any error (never throws).
 */
async function fetchFallbackMedia(url, signal) {
  if (!isFallbackConfigured()) return null;
  try {
    const res = await axios.post(
      config.fallbackApiUrl,
      { url },
      {
        headers: {
          Authorization: `Bearer ${config.fallbackApiKey}`,
          'Content-Type': 'application/json',
        },
        timeout: config.fallbackApiTimeoutMs,
        signal,
        validateStatus: () => true,
      },
    );
    if (res.status < 200 || res.status >= 300 || !res.data || typeof res.data !== 'object') {
      return null;
    }
    const mediaUrl =
      (typeof res.data.mediaUrl === 'string' && res.data.mediaUrl) ||
      (typeof res.data.videoUrl === 'string' && res.data.videoUrl) ||
      '';
    if (!mediaUrl) return null;
    const thumbnailUrl =
      typeof res.data.thumbnailUrl === 'string' && res.data.thumbnailUrl
        ? res.data.thumbnailUrl
        : null;
    return { ok: true, videoUrl: mediaUrl, thumbnailUrl, via: 'fallback_api' };
  } catch (_) {
    return null;
  }
}

module.exports = { isFallbackConfigured, fetchFallbackMedia };
