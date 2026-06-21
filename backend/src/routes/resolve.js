const express = require('express');
const { resolveInstagramUrl } = require('../services/instagramResolver');
const config = require('../config');

const router = express.Router();

/**
 * POST /resolve
 * body: { url: string, cursor?: string, userId?: string }
 */
router.post('/', async (req, res) => {
  try {
    const url = (req.body && req.body.url) || '';
    if (typeof url !== 'string' || url.trim().length === 0) {
      return res.status(400).json({ ok: false, error: 'invalid_url' });
    }
    if (url.length > 2048) {
      return res.status(400).json({ ok: false, error: 'invalid_url' });
    }

    const cursor = req.body?.cursor;
    const userId = req.body?.userId;
    const options = {};
    if (typeof cursor === 'string' && cursor.length > 0) {
      options.cursor = cursor;
    }
    if (typeof userId === 'string' && userId.length > 0) {
      options.userId = userId;
    }

    const result = await resolveInstagramUrl(url.trim(), options);

    if (!result.ok) {
      const status =
        result.error === 'invalid_url' ? 400 :
        result.error === 'private'    ? 403 :
        result.error === 'not_found'  ? 404 :
        result.error === 'resolver_failed' ? 502 :
                                        500;
      return res.status(status).json(result);
    }

    return res.json(result);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error('[resolve] unexpected error:', e);
    return res.status(500).json({ ok: false, error: 'internal' });
  }
});

module.exports = router;
