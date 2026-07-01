const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const config = require('./config');
const { createLogger, requestIdMiddleware } = require('./middleware/logger');
const { metricsAuthMiddleware } = require('./middleware/metricsAuth');
const { createRedisClient, closeRedisClient } = require('./redisClient');
const { resolveCache } = require('./services/resolveCache');
const resolveRouter = require('./routes/resolve');
const billingRouter = require('./routes/billing');
const { getMetrics } = require('./services/resolveMetrics');

const logger = createLogger();
const app = express();
const PORT = config.port;
const NODE_ENV = config.nodeEnv;

app.set('trust proxy', config.trustProxy);

app.use(
  helmet({
    contentSecurityPolicy: false,
  }),
);

const corsOptions = {
  origin:
    NODE_ENV === 'development'
      ? true
      : (() => {
          const raw = process.env.ALLOWED_ORIGINS || '';
          const list = raw
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);
          return list.length === 0 ? true : list;
        })(),
};
app.use(cors(corsOptions));

app.use(express.json({ limit: '64kb' }));
app.use(requestIdMiddleware(logger));

if (NODE_ENV !== 'test') {
  app.use(morgan(NODE_ENV === 'development' ? 'dev' : 'tiny'));
}

let redisClient;

function initRedis() {
  if (!config.redisUrl || NODE_ENV === 'test') return null;
  try {
    const client = createRedisClient();
    if (client) {
      redisClient = client;
      resolveCache.attachRedis(client);
    }
    return client;
  } catch (err) {
    logger.warn('redis_init_failed', { err: String(err) });
    return null;
  }
}

function createRateLimiter() {
  const baseOptions = {
    windowMs: config.rateLimitWindowMs,
    max: config.rateLimitMax,
    standardHeaders: true,
    legacyHeaders: false,
    message: { ok: false, error: 'rate_limited' },
  };

  const client = redisClient ?? initRedis();
  if (client) {
    try {
      // eslint-disable-next-line global-require
      const { RedisStore } = require('rate-limit-redis');
      return rateLimit({
        ...baseOptions,
        store: new RedisStore({
          sendCommand: (...args) => client.sendCommand(args),
        }),
      });
    } catch (err) {
      logger.warn('redis_rate_limit_unavailable', { err: String(err) });
    }
  }

  return rateLimit(baseOptions);
}

app.use('/resolve', createRateLimiter());

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'quicksave-backend',
    version: config.serviceVersion,
    uptime: process.uptime(),
  });
});

app.get('/health/live', (_req, res) => {
  res.json({ ok: true, live: true });
});

app.get('/version', (_req, res) => {
  res.json({
    ok: true,
    service: 'quicksave-backend',
    version: config.serviceVersion,
  });
});

app.get('/health/ready', async (_req, res) => {
  const client = redisClient ?? initRedis();
  let redis = 'disabled';
  if (client) {
    try {
      await client.ping();
      redis = 'ok';
    } catch {
      redis = 'error';
    }
  }
  res.json({ ok: true, ready: true, redis });
});

app.get('/health/metrics', metricsAuthMiddleware, (_req, res) => {
  const m = getMetrics();
  res.json({ ok: true, metrics: m, alert: m.alert });
});

app.use('/resolve', resolveRouter);
app.use('/billing', billingRouter);

const webBuildDir = (() => {
  const packaged = path.join(__dirname, '..', 'public', 'web');
  const local = path.join(__dirname, '..', '..', 'build', 'web');
  // eslint-disable-next-line global-require
  const fs = require('fs');
  if (fs.existsSync(path.join(packaged, 'index.html'))) return packaged;
  return local;
})();
app.use(express.static(webBuildDir));

app.get(/^\/(?!api|resolve|health).*/, (req, res) => {
  res.sendFile(path.join(webBuildDir, 'index.html'));
});

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    error: 'not_found',
    code: 'NOT_FOUND',
    requestId: req.id,
  });
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, _next) => {
  logger.error('unhandled_error', { reqId: req.id, err: String(err) });
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({
      ok: false,
      error: 'invalid_json',
      code: 'INVALID_JSON',
      requestId: req.id,
    });
  }
  if (err.type === 'entity.too.large') {
    return res.status(413).json({
      ok: false,
      error: 'payload_too_large',
      code: 'PAYLOAD_TOO_LARGE',
      requestId: req.id,
    });
  }
  res.status(500).json({
    ok: false,
    error: 'internal',
    code: 'INTERNAL',
    requestId: req.id,
  });
});

let server;

if (require.main === module) {
  server = app.listen(PORT, () => {
    logger.info('server_started', { port: PORT, env: NODE_ENV });
  });

  const shutdown = (signal) => {
    logger.info('shutdown', { signal });
    if (server) {
      server.close(() => {
        closeRedisClient().finally(() => process.exit(0));
      });
    } else {
      process.exit(0);
    }
    setTimeout(() => process.exit(1), 10000).unref();
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

module.exports = app;
