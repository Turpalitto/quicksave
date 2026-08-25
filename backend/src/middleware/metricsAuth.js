const crypto = require('crypto');
const config = require('../config');

/**
 * Constant-time token comparison to prevent timing attacks.
 */
function tokensMatch(provided, expected) {
  const a = Buffer.from(String(provided));
  const b = Buffer.from(String(expected));
  if (a.length !== b.length) {
    // Keep timing roughly uniform for mismatched lengths.
    crypto.timingSafeEqual(b, b);
    return false;
  }
  return crypto.timingSafeEqual(a, b);
}

/**
 * Protects /health/metrics unless METRICS_PUBLIC=true or no token configured in dev.
 */
function metricsAuthMiddleware(req, res, next) {
  if (config.metricsPublic) {
    return next();
  }

  const token = config.metricsToken;
  if (!token) {
    return res.status(503).json({
      ok: false,
      error: 'metrics_disabled',
      code: 'METRICS_DISABLED',
    });
  }

  const auth = req.headers.authorization || '';
  const bearer = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  const headerToken = req.headers['x-metrics-token'] || bearer;

  if (!headerToken || !tokensMatch(headerToken, token)) {
    return res.status(401).json({
      ok: false,
      error: 'metrics_unauthorized',
      code: 'METRICS_UNAUTHORIZED',
    });
  }

  return next();
}

module.exports = { metricsAuthMiddleware, tokensMatch };
