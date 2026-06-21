/**
 * Application configuration from environment variables.
 */

const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  trustProxy: parseInt(process.env.TRUST_PROXY || '1', 10),
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX || '30', 10),
  requestTimeoutMs: parseInt(process.env.REQUEST_TIMEOUT_MS || '15000', 10),
  resolveDeadlineMs: parseInt(process.env.RESOLVE_DEADLINE_MS || '25000', 10),
  cacheTtlMs: parseInt(process.env.CACHE_TTL_MS || '600000', 10),
  cacheMaxEntries: parseInt(process.env.CACHE_MAX_ENTRIES || '500', 10),
  cacheRedisEnabled: process.env.CACHE_REDIS !== '0',
  upstreamPoolSize: parseInt(process.env.UPSTREAM_POOL_SIZE || '3', 10),
  redisUrl: process.env.REDIS_URL || '',
  logLevel: process.env.LOG_LEVEL || 'info',
};

module.exports = config;
