/**
 * Shared helpers for QuickSave browser extension (MV3).
 * Privacy: only URLs the user explicitly opened or clicked.
 */

export const DEFAULT_DASHBOARD_URL = 'https://quicksave-api.onrender.com';
export const DEFAULT_BACKEND_URL = 'https://quicksave-api.onrender.com';

const PUBLIC_PATHS = [
  '/p/',
  '/reel/',
  '/reels/',
  '/tv/',
  '/stories/highlights/',
  '/video/reel/',
];

/**
 * @param {string} raw
 * @returns {string|null}
 */
export function normalizeInstagramUrl(raw) {
  if (!raw || typeof raw !== 'string') return null;
  let value = raw.trim();
  if (!value) return null;

  if (!/^https?:\/\//i.test(value)) {
    if (value.startsWith('instagram.com') || value.startsWith('www.instagram.com')) {
      value = `https://${value}`;
    } else {
      return null;
    }
  }

  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    return null;
  }

  const host = parsed.hostname.replace(/^www\./, '');
  if (host !== 'instagram.com' && host !== 'instagr.am') return null;

  const path = parsed.pathname.endsWith('/')
    ? parsed.pathname.slice(0, -1)
    : parsed.pathname;

  if (path === '/reels' || path.startsWith('/reels/')) {
    return `https://www.instagram.com${path}/`;
  }

  const isPublic = PUBLIC_PATHS.some((p) => path.includes(p));
  if (!isPublic) {
    return null;
  }

  parsed.hash = '';
  parsed.search = '';
  return parsed.toString();
}

/**
 * @param {string} url
 * @returns {boolean}
 */
export function isSaveableInstagramPage(url) {
  return normalizeInstagramUrl(url) != null;
}

/**
 * @param {string} pageUrl
 * @param {string} dashboardBase
 * @returns {string}
 */
export function buildDashboardResolveUrl(pageUrl, dashboardBase) {
  const base = (dashboardBase || DEFAULT_DASHBOARD_URL).replace(/\/$/, '');
  const normalized = normalizeInstagramUrl(pageUrl);
  if (!normalized) return base;
  return `${base}/?url=${encodeURIComponent(normalized)}`;
}

/**
 * @param {import('chrome').storage.StorageArea} area
 * @returns {Promise<{dashboardUrl: string, backendUrl: string, backendMode: string}>}
 */
export async function loadSettings(area) {
  const defaults = {
    dashboardUrl: DEFAULT_DASHBOARD_URL,
    backendUrl: DEFAULT_BACKEND_URL,
    backendMode: 'hosted',
  };
  const stored = await area.get(defaults);
  return {
    dashboardUrl: stored.dashboardUrl || defaults.dashboardUrl,
    backendUrl: stored.backendUrl || defaults.backendUrl,
    backendMode: stored.backendMode || defaults.backendMode,
  };
}
