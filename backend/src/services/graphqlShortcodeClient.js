const axios = require('axios');
const { findVideoUrlInJson, findThumbnailInJson } = require('./postExtractor');

const SHORTCODE_DOC_ID = '24368985919464652';

function extractLsdToken(html) {
  if (!html || typeof html !== 'string') return '';
  return (
    html.match(/"LSD",\[\],\{"token":"([^"]+)"\}/)?.[1] ||
    html.match(/"lsd":"([^"]+)"/)?.[1] ||
    ''
  );
}

function parseCookieJar(setCookieHeaders, jar = {}) {
  if (!setCookieHeaders) return jar;
  for (const c of setCookieHeaders) {
    const [kv] = c.split(';');
    const eq = kv.indexOf('=');
    if (eq > 0) jar[kv.slice(0, eq)] = kv.slice(eq + 1);
  }
  return jar;
}

function cookieHeader(jar) {
  return Object.entries(jar)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ');
}

/**
 * GraphQL shortcode lookup (session bootstrap via page GET).
 * Returns { videoUrl, thumbnailUrl, rawData } or empty on failure.
 */
async function fetchGraphqlShortcodeMedia(pageUrl, shortcode, userAgent) {
  const jar = {};
  let html = '';

  try {
    const pageRes = await axios.get(pageUrl, {
      timeout: 15000,
      maxRedirects: 5,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en-US,en;q=0.9',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        Referer: 'https://www.instagram.com/',
      },
    });
    parseCookieJar(pageRes.headers['set-cookie'], jar);
    html = typeof pageRes.data === 'string' ? pageRes.data : '';
  } catch (_) {
    return { videoUrl: null, thumbnailUrl: null, rawData: null };
  }

  const csrf = jar.csrftoken || '';
  const lsd = extractLsdToken(html);
  const variables = encodeURIComponent(JSON.stringify({ shortcode }));
  const body = `variables=${variables}&doc_id=${SHORTCODE_DOC_ID}&lsd=${encodeURIComponent(lsd)}`;

  try {
    const gqlRes = await axios.post('https://www.instagram.com/graphql/query', body, {
      timeout: 15000,
      validateStatus: (s) => s >= 200 && s < 500,
      headers: {
        'User-Agent': userAgent,
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-IG-App-ID': '936619743392459',
        'X-CSRFToken': csrf,
        'X-FB-LSD': lsd,
        'X-ASBD-ID': '129477',
        Referer: pageUrl,
        Cookie: cookieHeader(jar),
        'Accept-Language': 'en-US,en;q=0.9',
      },
    });

    const data = gqlRes.data;
    if (!data || typeof data !== 'object') {
      return { videoUrl: null, thumbnailUrl: null, rawData: null };
    }

    const media =
      data.data?.xdt_shortcode_media ||
      data.data?.xdt_api__v1__media__shortcode__web_info?.items?.[0] ||
      null;

    const videoUrl =
      media?.video_url ||
      findVideoUrlInJson(data) ||
      null;
    const thumbnailUrl =
      media?.thumbnail_src ||
      media?.display_url ||
      findThumbnailInJson(data) ||
      null;

    return { videoUrl, thumbnailUrl, rawData: data };
  } catch (_) {
    return { videoUrl: null, thumbnailUrl: null, rawData: null };
  }
}

module.exports = {
  fetchGraphqlShortcodeMedia,
  extractLsdToken,
  SHORTCODE_DOC_ID,
};
