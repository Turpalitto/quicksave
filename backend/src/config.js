/**
 * Application configuration from environment variables.
 */

const { readFileSync } = require('fs');
const { join } = require('path');

const pkg = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf8'));

const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  trustProxy: parseInt(process.env.TRUST_PROXY || '1', 10),
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || '30', 10),
  requestTimeoutMs: parseInt(process.env.REQUEST_TIMEOUT_MS || '15000', 10),
  resolveDeadlineMs: parseInt(process.env.RESOLVE_DEADLINE_MS || '45000', 10),
  cacheTtlMs: parseInt(process.env.CACHE_TTL_MS || '600000', 10),
  cacheMaxEntries: parseInt(process.env.CACHE_MAX_ENTRIES || '500', 10),
  cacheRedisEnabled: process.env.CACHE_REDIS !== '0',
  upstreamPoolSize: parseInt(process.env.UPSTREAM_POOL_SIZE || '3', 10),
  redisUrl: process.env.REDIS_URL || '',
  logLevel: process.env.LOG_LEVEL || 'info',
  metricsToken: process.env.METRICS_TOKEN || '',
  metricsPublic: process.env.METRICS_PUBLIC === 'true',
  serviceVersion: process.env.SERVICE_VERSION || pkg.version,
  /** Optional browser cookies: "sessionid=...; csrftoken=..." for higher resolve rate */
  instagramCookies: process.env.INSTAGRAM_COOKIES || '',
  /**
   * Pool of cookie jars for rotation ("||"-separated). Each entry uses the same
   * format as INSTAGRAM_COOKIES. Rotating spreads per-session rate limits.
   */
  instagramCookiesPool: (process.env.INSTAGRAM_COOKIES_POOL || '')
    .split('||')
    .map((s) => s.trim())
    .filter(Boolean),
  /** Use Google/Cloudflare DNS for Instagram (fixes router DNS blocks). Set to 0 to disable. */
  usePublicDnsForInstagram: process.env.USE_PUBLIC_DNS !== '0',
  instagramDnsServers: process.env.INSTAGRAM_DNS_SERVERS || '8.8.8.8,1.1.1.1,8.8.4.4',
  /**
   * Stale-while-revalidate: on resolver failure serve an expired cache entry
   * (flagged stale:true) instead of an error. Set to 0 to disable.
   */
  staleWhileRevalidate: process.env.STALE_WHILE_REVALIDATE !== '0',
  /** Optional paid fallback provider: POST {url} -> {mediaUrl, ...}. Disabled unless both set. */
  fallbackApiUrl: process.env.FALLBACK_API_URL || '',
  fallbackApiKey: process.env.FALLBACK_API_KEY || '',
  fallbackApiTimeoutMs: parseInt(process.env.FALLBACK_API_TIMEOUT_MS || '15000', 10),
  /** Remote config for clients. minVersion forces app update when below it. */
  remoteMinClientVersion: process.env.REMOTE_MIN_CLIENT_VERSION || '',
  remoteFlags: (() => {
    try {
      const parsed = JSON.parse(process.env.REMOTE_FLAGS || '{}');
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {};
    } catch (_) {
      return {};
    }
  })(),
};

module.exports = config;
