const { randomUUID } = require('crypto');

function createLogger() {
  const level = process.env.LOG_LEVEL || 'info';
  const levels = { debug: 0, info: 1, warn: 2, error: 3 };
  const min = levels[level] ?? 1;

  function log(lvl, msg, meta = {}) {
    if ((levels[lvl] ?? 1) < min) return;
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      level: lvl,
      msg,
      ...meta,
    });
    if (lvl === 'error') process.stderr.write(`${line}\n`);
    else process.stdout.write(`${line}\n`);
  }

  return {
    debug: (msg, meta) => log('debug', msg, meta),
    info: (msg, meta) => log('info', msg, meta),
    warn: (msg, meta) => log('warn', msg, meta),
    error: (msg, meta) => log('error', msg, meta),
  };
}

function requestIdMiddleware(logger) {
  return (req, res, next) => {
    const reqId = req.headers['x-request-id'] || randomUUID();
    req.id = reqId;
    res.setHeader('X-Request-Id', reqId);
    const start = Date.now();
    res.on('finish', () => {
      logger.info('request', {
        reqId,
        method: req.method,
        path: req.path,
        status: res.statusCode,
        ms: Date.now() - start,
      });
    });
    next();
  };
}

module.exports = { createLogger, requestIdMiddleware };
