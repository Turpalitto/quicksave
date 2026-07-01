/**
 * Optional Instagram session cookies from env + www_claim propagation.
 * Pattern from gallery-dl / yt-dlp: sessionid dramatically improves success rate.
 */

const config = require('../config');

function parseCookieString(raw) {
  const jar = {};
  if (!raw || typeof raw !== 'string') return jar;
  for (const part of raw.split(';')) {
    const trimmed = part.trim();
    const eq = trimmed.indexOf('=');
    if (eq > 0) jar[trimmed.slice(0, eq)] = trimmed.slice(eq + 1);
  }
  return jar;
}

function loadEnvCookieJar() {
  const raw = config.instagramCookies || '';
  if (!raw.trim()) return {};
  const trimmed = raw.trim();
  if (trimmed.startsWith('{')) {
    try {
      const parsed = JSON.parse(trimmed);
      if (parsed && typeof parsed === 'object') return { ...parsed };
    } catch (_) {}
  }
  return parseCookieString(trimmed);
}

function mergeCookieJars(...jars) {
  return Object.assign({}, ...jars);
}

function cookieHeader(jar) {
  return Object.entries(jar)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ');
}

function parseSetCookieHeaders(setCookieHeaders, jar = {}) {
  if (!setCookieHeaders) return jar;
  for (const c of setCookieHeaders) {
    const [kv] = c.split(';');
    const eq = kv.indexOf('=');
    if (eq > 0) jar[kv.slice(0, eq)] = kv.slice(eq + 1);
  }
  return jar;
}

/** Capture x-ig-set-www-claim from Instagram API responses (gallery-dl pattern). */
function applyWwwClaimFromResponse(headers, state = {}) {
  if (!headers) return state.wwwClaim || '';
  const claim =
    headers['x-ig-set-www-claim'] ||
    headers['X-IG-Set-WWW-Claim'] ||
    null;
  if (claim) state.wwwClaim = claim;
  return state.wwwClaim || '';
}

function createSessionState() {
  return {
    jar: mergeCookieJars(loadEnvCookieJar()),
    wwwClaim: '',
  };
}

module.exports = {
  loadEnvCookieJar,
  mergeCookieJars,
  cookieHeader,
  parseSetCookieHeaders,
  applyWwwClaimFromResponse,
  createSessionState,
};
