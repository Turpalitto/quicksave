const config = require('../config');

const metrics = {
  total: 0,
  success: 0,
  failures: {},
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
  }
}

function getMetrics() {
  const failureTotal = metrics.total - metrics.success;
  const successRate = metrics.total > 0
    ? Math.round((metrics.success / metrics.total) * 1000) / 10
    : 100;
  return {
    total: metrics.total,
    success: metrics.success,
    failures: metrics.failures,
    failureTotal,
    successRate,
    uptimeSec: Math.round((Date.now() - metrics.startedAt) / 1000),
    alert: metrics.total >= 20 && successRate < 70,
  };
}

function resetMetrics() {
  metrics.total = 0;
  metrics.success = 0;
  metrics.failures = {};
  metrics.startedAt = Date.now();
}

module.exports = { recordResolve, getMetrics, resetMetrics };
