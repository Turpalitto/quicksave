const crypto = require('crypto');

/**
 * Returns a short hash of a URL for logs (never log full user URLs in production).
 */
function hashUrl(url) {
  if (!url || typeof url !== 'string') return 'empty';
  return crypto.createHash('sha256').update(url.trim()).digest('hex').slice(0, 12);
}

/**
 * Redacts query params and truncates for debug logs.
 */
function sanitizeUrlForLog(url) {
  if (!url || typeof url !== 'string') return '';
  try {
    const u = new URL(url.trim());
    const host = u.hostname.replace(/^www\./, '');
    const path = u.pathname.length > 48 ? `${u.pathname.slice(0, 48)}…` : u.pathname;
    return `${host}${path}`;
  } catch {
    return hashUrl(url);
  }
}

module.exports = { hashUrl, sanitizeUrlForLog };
