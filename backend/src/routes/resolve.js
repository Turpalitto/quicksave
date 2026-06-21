const express = require('express');
const { resolveInstagramUrl } = require('../services/instagramResolver');
const { createLogger } = require('../middleware/logger');
const { sanitizeUrlForLog } = require('../utils/urlSanitizer');

const router = express.Router();
const logger = createLogger();

const ERROR_STATUS = {
  invalid_url: { status: 400, code: 'INVALID_URL' },
  private: { status: 403, code: 'CONTENT_PRIVATE' },
  not_found: { status: 404, code: 'CONTENT_NOT_FOUND' },
  resolver_failed: { status: 502, code: 'RESOLVER_FAILED' },
  upstream_timeout: { status: 504, code: 'UPSTREAM_TIMEOUT' },
  rate_limited: { status: 429, code: 'RATE_LIMITED' },
};

/**
 * POST /resolve
 * body: { url: string, cursor?: string, userId?: string }
 */
router.post('/', async (req, res) => {
  const requestId = req.id;
  try {
    const url = (req.body && req.body.url) || '';
    if (typeof url !== 'string' || url.trim().length === 0) {
      return res.status(400).json({
        ok: false,
        error: 'invalid_url',
        code: 'INVALID_URL',
        requestId,
      });
    }
    if (url.length > 2048) {
      return res.status(400).json({
        ok: false,
        error: 'invalid_url',
        code: 'INVALID_URL',
        requestId,
      });
    }

    const cursor = req.body?.cursor;
    const userId = req.body?.userId;
    const options = { requestId };
    if (typeof cursor === 'string' && cursor.length > 0) {
      options.cursor = cursor;
    }
    if (typeof userId === 'string' && userId.length > 0) {
      options.userId = userId;
    }

    const sanitized = sanitizeUrlForLog(url);
    logger.info('resolve_start', { reqId: requestId, url: sanitized });

    const result = await resolveInstagramUrl(url.trim(), options);

    if (!result.ok) {
      const mapped = ERROR_STATUS[result.error] || { status: 500, code: 'RESOLVE_ERROR' };
      logger.warn('resolve_failed', {
        reqId: requestId,
        url: sanitized,
        error: result.error,
        code: mapped.code,
      });
      return res.status(mapped.status).json({
        ...result,
        code: mapped.code,
        requestId,
      });
    }

    logger.info('resolve_success', { reqId: requestId, url: sanitized });
    return res.json({ ...result, requestId });
  } catch (e) {
    logger.error('resolve_unexpected', {
      reqId: requestId,
      err: String(e),
    });
    return res.status(500).json({
      ok: false,
      error: 'internal',
      code: 'INTERNAL',
      requestId,
    });
  }
});

module.exports = router;
