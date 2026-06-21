const { isProfileUrl } = require('./profileExtractor');

const PUBLIC_PATTERNS = [
  /^https?:\/\/(www\.)?instagram\.com\/(reel|p|tv)\/[A-Za-z0-9_\-]+$/i,
  /^https?:\/\/(www\.)?instagr\.am\/(reel|p|tv)\/[A-Za-z0-9_\-]+$/i,
  /^https?:\/\/(www\.)?instagram\.com\/stories\/[^/]+\/\d+$/i,
  /^https?:\/\/(www\.)?instagram\.com\/stories\/highlights\/\d+$/i,
];

const POST_PATTERNS = PUBLIC_PATTERNS;

function normalizeUrl(url) {
  let u = url.trim();
  if (!/^https?:\/\//i.test(u)) u = `https://${u}`;

  u = u.replace(/\/\/(www\.)?instagr\.com\//i, '//$1instagram.com/');

  try {
    const parsed = new URL(u);
    parsed.search = '';
    parsed.hash = '';
    u = parsed.toString();
  } catch (_) {
    const q = u.indexOf('?');
    if (q >= 0) u = u.slice(0, q);
    const h = u.indexOf('#');
    if (h >= 0) u = u.slice(0, h);
  }

  u = u.replace(
    /instagram\.com\/(?:video\/|share\/)?(reels|reel|p|tv)\//gi,
    'instagram.com/$1/'
  );
  u = u.replace(/instagram\.com\/reels\//gi, 'instagram.com/reel/');
  u = u.replace(
    /instagr\.am\/(?:video\/|share\/)?(reels|reel|p|tv)\//gi,
    'instagr.am/$1/'
  );
  u = u.replace(/instagr\.am\/reels\//gi, 'instagr.am/reel/');
  u = u.replace(
    /instagram\.com\/stories\/([^/]+)\/(\d+)\/[^/]+/gi,
    'instagram.com/stories/$1/$2'
  );

  if (u.endsWith('/')) u = u.slice(0, -1);
  return u;
}

function isValidPublicUrl(url) {
  const normalized = normalizeUrl(url);
  if (isProfileUrl(normalized)) return true;
  return POST_PATTERNS.some((re) => re.test(normalized));
}

function extractShortcode(url) {
  const storyMatch = url.match(/\/stories\/(?:highlights\/)?([^/]+)(?:\/(\d+))?$/i);
  if (storyMatch) {
    const id = storyMatch[2] || storyMatch[1];
    return id.replace(/[^A-Za-z0-9_\-]/g, '') || 'story';
  }
  const m = url.match(/\/(reel|p|tv)\/([A-Za-z0-9_\-]+)/i);
  return m ? m[2] : (url.split('/').filter(Boolean).pop() || 'media');
}

function getUrlKind(url) {
  if (isProfileUrl(url)) return 'profile';
  if (/\/stories\/highlights\//i.test(url)) return 'highlight';
  if (/\/stories\//i.test(url)) return 'story';
  return 'post';
}

function buildStoryEmbedUrl(canonicalUrl) {
  const host = 'www.instagram.com';
  if (/\/stories\/highlights\//i.test(canonicalUrl)) {
    const id = canonicalUrl.split('/').filter(Boolean).pop();
    return `https://${host}/stories/highlights/${id}/`;
  }
  return canonicalUrl;
}

function buildEmbedUrl(canonicalUrl) {
  const kind = getUrlKind(canonicalUrl);
  if (kind === 'story' || kind === 'highlight') {
    return buildStoryEmbedUrl(canonicalUrl);
  }
  const typeMatch = canonicalUrl.match(/\/(reel|p|tv)\//i);
  const type = typeMatch ? typeMatch[1] : 'reel';
  const shortcode = extractShortcode(canonicalUrl);
  const host = canonicalUrl.includes('instagr.am') ? 'www.instagr.am' : 'www.instagram.com';
  return `https://${host}/${type}/${shortcode}/embed/captioned/`;
}

module.exports = {
  PUBLIC_PATTERNS,
  POST_PATTERNS,
  normalizeUrl,
  isValidPublicUrl,
  extractShortcode,
  getUrlKind,
  buildEmbedUrl,
  buildStoryEmbedUrl,
};
