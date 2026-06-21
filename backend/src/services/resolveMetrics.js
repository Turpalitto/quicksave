const config = require('../config');

const metrics = {
  total: 0,
  success: 0,
  failures: {},
  cacheHits: 0,
  cacheMisses: 0,
  upstreamTimeouts: 0,
  rateLimitHits: 0,
  startedAt: Date.now(),
};

function recordResolve(result) {
  if (config.nodeEnv === 'test') return;
  metrics.total += 1;
  if (result && result.ok === true) {
    metrics.success += 1;
  } else {
    const key = (result && result.error) || 'unknown';
    metrics.failures[key] = (metrics.failures[key] || 0) + 1;
    if (key === 'upstream_timeout') {
      metrics.upstreamTimeouts += 1;
    }
  }
}

function recordCacheHit() {
  if (config.nodeEnv === 'test') return;
  metrics.cacheHits += 1;
}

function recordCacheMiss() {
  if (config.nodeEnv === 'test') return;
  metrics.cacheMisses += 1;
}

function recordRateLimitHit() {
  if (config.nodeEnv === 'test') return;
  metrics.rateLimitHits += 1;
}

function getMetrics() {
  const failureTotal = metrics.total - metrics.success;
  const successRate =
    metrics.total > 0 ? Math.round((metrics.success / metrics.total) * 1000) / 10 : 100;
  const cacheTotal = metrics.cacheHits + metrics.cacheMisses;
  const cacheHitRate =
    cacheTotal > 0 ? Math.round((metrics.cacheHits / cacheTotal) * 1000) / 10 : 0;
  return {
    total: metrics.total,
    success: metrics.success,
    failures: metrics.failures,
    failureTotal,
    successRate,
    cacheHits: metrics.cacheHits,
    cacheMisses: metrics.cacheMisses,
    cacheHitRate,
    upstreamTimeouts: metrics.upstreamTimeouts,
    rateLimitHits: metrics.rateLimitHits,
    uptimeSec: Math.round((Date.now() - metrics.startedAt) / 1000),
    alert: metrics.total >= 20 && successRate < 70,
  };
}

function resetMetrics() {
  metrics.total = 0;
  metrics.success = 0;
  metrics.failures = {};
  metrics.cacheHits = 0;
  metrics.cacheMisses = 0;
  metrics.upstreamTimeouts = 0;
  metrics.rateLimitHits = 0;
  metrics.startedAt = Date.now();
}

module.exports = {
  recordResolve,
  recordCacheHit,
  recordCacheMiss,
  recordRateLimitHit,
  getMetrics,
  resetMetrics,
};
