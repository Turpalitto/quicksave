const config = require('./config');
const { createLogger } = require('./middleware/logger');

const logger = createLogger();

let client = null;
let connectStarted = false;

/**
 * Creates or returns the shared Redis client (lazy connect).
 * Returns null when REDIS_URL is unset or in test env.
 */
function createRedisClient() {
  if (!config.redisUrl || config.nodeEnv === 'test') return null;
  if (client) return client;

  try {
    // eslint-disable-next-line global-require
    const { createClient } = require('redis');
    client = createClient({ url: config.redisUrl });
    client.on('error', (err) => {
      logger.warn('redis_error', { err: String(err) });
    });
    if (!connectStarted) {
      connectStarted = true;
      client.connect().catch((err) => {
        logger.warn('redis_connect_failed', { err: String(err) });
      });
    }
    return client;
  } catch (err) {
    logger.warn('redis_unavailable', { err: String(err) });
    return null;
  }
}

function getRedisClient() {
  return client;
}

async function closeRedisClient() {
  if (client) {
    await client.quit();
    client = null;
    connectStarted = false;
  }
}

module.exports = { createRedisClient, getRedisClient, closeRedisClient };
