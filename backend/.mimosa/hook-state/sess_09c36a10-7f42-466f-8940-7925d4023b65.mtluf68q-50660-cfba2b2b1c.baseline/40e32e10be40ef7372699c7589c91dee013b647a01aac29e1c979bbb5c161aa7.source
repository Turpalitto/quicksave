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
  const claim = headers['x-ig-set-www-claim'] || headers['X-IG-Set-WWW-Claim'] || null;
  if (claim) state.wwwClaim = claim;
  return state.wwwClaim || '';
}

function createSessionState() {
  // When a cookie pool is configured, each session takes the next jar
  // (round-robin) instead of the single INSTAGRAM_COOKIES jar — rotating
  // identities spreads per-session rate limits across requests.
  const pooled = nextPooledCookieJar();
  return {
    jar: pooled || mergeCookieJars(loadEnvCookieJar()),
    wwwClaim: '',
  };
}

/** Module-level round-robin counter over the cookie pool. */
let poolCounter = 0;

/**
 * Pick the next cookie jar from the INSTAGRAM_COOKIES_POOL (round-robin).
 * Returns null when the pool is empty (single-jar mode via INSTAGRAM_COOKIES).
 */
function nextPooledCookieJar() {
  const pool = config.instagramCookiesPool || [];
  if (!Array.isArray(pool) || pool.length === 0) return null;
  const idx = Math.abs(poolCounter) % pool.length;
  poolCounter += 1;
  return loadCookieJarFromRaw(pool[idx]);
}

/** Parse one pool entry using the same rules as INSTAGRAM_COOKIES (JSON or k=v;...). */
function loadCookieJarFromRaw(raw) {
  const trimmed = (raw || '').trim();
  if (!trimmed) return {};
  if (trimmed.startsWith('{')) {
    try {
      const parsed = JSON.parse(trimmed);
      if (parsed && typeof parsed === 'object') return { ...parsed };
    } catch (_) {}
  }
  return parseCookieString(trimmed);
}

function resetPoolCounter() {
  poolCounter = 0;
}

module.exports = {
  loadEnvCookieJar,
  loadCookieJarFromRaw,
  nextPooledCookieJar,
  resetPoolCounter,
  mergeCookieJars,
  cookieHeader,
  parseSetCookieHeaders,
  applyWwwClaimFromResponse,
  createSessionState,
};
