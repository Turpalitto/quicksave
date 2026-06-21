const express = require('express');
const config = require('../config');

const router = express.Router();

/**
 * POST /billing/play/verify
 * Optional server-side Play purchase validation.
 *
 * Set BILLING_PLAY_VERIFY=1 and implement Google Play Developer API in production.
 * Default: 501 — client may treat as "verification skipped" in dev/self-hosted mode.
 */
router.post('/play/verify', (req, res) => {
  const { productId, purchaseToken, packageName } = req.body || {};

  if (!productId || !purchaseToken || !packageName) {
    return res.status(400).json({
      ok: false,
      valid: false,
      code: 'INVALID_BODY',
    });
  }

  if (process.env.BILLING_PLAY_VERIFY !== '1') {
    return res.status(501).json({
      ok: false,
      valid: false,
      code: 'BILLING_VERIFY_NOT_CONFIGURED',
      message: 'Server-side Play verification is not enabled',
    });
  }

  if (process.env.BILLING_DEV_ACCEPT === '1') {
    return res.json({ ok: true, valid: true, mode: 'dev_accept' });
  }

  return res.status(501).json({
    ok: false,
    valid: false,
    code: 'BILLING_VERIFY_NOT_IMPLEMENTED',
    message: 'Configure Google Play Developer API for production validation',
  });
});

module.exports = router;
