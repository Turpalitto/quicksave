const axios = require('axios');
const config = require('../config');
const { findVideoUrlInJson, findThumbnailInJson } = require('./postExtractor');
const { extractShortcode } = require('./urlNormalizer');
const igHttp = require('../utils/instagramHttp');
const {
  cookieHeader,
  parseSetCookieHeaders,
  applyWwwClaimFromResponse,
  createSessionState,
} = require('./instagramSession');

const USER_AGENTS = [
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 ' +
    '(KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
];

const REQUEST_TIMEOUT = config.requestTimeoutMs;
const MAX_REDIRECTS = 5;

function parseCookieJar(setCookieHeaders, jar = {}) {
  return parseSetCookieHeaders(setCookieHeaders, jar);
}

async function fetchSessionCookies(userAgent) {
  const session = createSessionState();
  const jar = session.jar;
  try {
    const res = await igHttp.get('https://www.instagram.com/', {
      timeout: REQUEST_TIMEOUT,
      maxRedirects: MAX_REDIRECTS,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en-US,en;q=0.9',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        ...(cookieHeader(jar) ? { Cookie: cookieHeader(jar) } : {}),
      },
    });
    parseCookieJar(res.headers['set-cookie'], jar);
    applyWwwClaimFromResponse(res.headers, session);
  } catch (_) {
    // session bootstrap is best-effort
  }
  return { jar, wwwClaim: session.wwwClaim };
}

async function fetchHtml(url, userAgent, maxAttempts = 2, cookies = {}) {
  let lastError;
  const cookieStr = cookieHeader(cookies);
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await igHttp.get(url, {
        timeout: REQUEST_TIMEOUT,
        maxRedirects: MAX_REDIRECTS,
        validateStatus: (s) => s >= 200 && s < 400,
        headers: {
          'User-Agent': userAgent,
          'Accept-Language': 'en-US,en;q=0.9',
          Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          Referer: 'https://www.instagram.com/',
          ...(cookieStr ? { Cookie: cookieStr } : {}),
        },
      });
    } catch (err) {
      lastError = err;
      const status = err.response && err.response.status;
      if (status && status >= 400 && status < 500 && status !== 429) {
        throw err;
      }
      if (attempt < maxAttempts) {
        const delay = Math.min(400 * 2 ** (attempt - 1), 2000);
        await new Promise((r) => setTimeout(r, delay));
      }
    }
  }
  throw lastError;
}

async function fetchHtmlSources(pageUrl, embedUrl) {
  const { jar: sessionCookies } = await fetchSessionCookies(USER_AGENTS[0]);
  const jobs = [];
  for (const ua of USER_AGENTS) {
    jobs.push({
      source: 'page',
      ua,
      url: pageUrl,
      attempts: 2,
      cookies: sessionCookies,
    });
    jobs.push({ source: 'embed', ua, url: embedUrl, attempts: 1, cookies: {} });
  }

  const poolSize = Math.max(1, config.upstreamPoolSize);
  const results = new Array(jobs.length);
  let nextJob = 0;

  async function worker() {
    while (nextJob < jobs.length) {
      const idx = nextJob++;
      const job = jobs[idx];
      try {
        const res = await fetchHtml(job.url, job.ua, job.attempts, job.cookies);
        results[idx] = { source: job.source, ua: job.ua, res };
      } catch (err) {
        results[idx] = { source: job.source, ua: job.ua, err };
      }
    }
  }

  await Promise.all(Array.from({ length: Math.min(poolSize, jobs.length) }, () => worker()));
  return results.filter(Boolean);
}

async function fetchGraphqlVideoUrl(pageUrl, userAgent) {
  const shortcode = extractShortcode(pageUrl);
  const { jar, wwwClaim } = await fetchSessionCookies(userAgent);
  const cookieStr = cookieHeader(jar);
  const apiHeaders = {
    'User-Agent': userAgent,
    Accept: 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
    'x-ig-app-id': '936619743392459',
    'X-ASBD-ID': '198387',
    'X-IG-WWW-Claim': wwwClaim || '0',
    'X-Requested-With': 'XMLHttpRequest',
    Origin: 'https://www.instagram.com',
    Referer: pageUrl,
    ...(jar.csrftoken ? { 'X-CSRFToken': jar.csrftoken } : {}),
    ...(cookieStr ? { Cookie: cookieStr } : {}),
  };

  const endpoints = [
    `https://www.instagram.com/api/v1/media/shortcode/${shortcode}/`,
    `https://www.instagram.com/api/v1/media/${shortcode}/info/`,
  ];

  for (const apiUrl of endpoints) {
    try {
      const response = await igHttp.get(apiUrl, {
        timeout: REQUEST_TIMEOUT,
        maxRedirects: MAX_REDIRECTS,
        validateStatus: (s) => s >= 200 && s < 400,
        headers: apiHeaders,
      });
      const data = response.data;
      let parsed = data;
      if (typeof data === 'string') {
        try {
          parsed = JSON.parse(data);
        } catch (_) {
          parsed = null;
        }
      }
      const item = parsed?.items?.[0] || parsed;
      if (item && typeof item === 'object') {
        const videoUrl = findVideoUrlInJson(item);
        if (videoUrl) {
          return {
            videoUrl,
            thumbnailUrl: findThumbnailInJson(item),
            rawData: parsed,
          };
        }
      }
    } catch (err) {
      const status = err && err.response && err.response.status;
      if (status === 404) {
        const e = new Error('not_found');
        e.code = 'not_found';
        throw e;
      }
    }
  }

  return { videoUrl: null, thumbnailUrl: null, rawData: null };
}

async function fetchOembedFromEndpoint(baseUrl, pageUrl, userAgent) {
  const response = await igHttp.get(baseUrl, {
    params: { url: pageUrl, omitscript: true },
    timeout: 8000,
    validateStatus: (s) => s >= 200 && s < 400,
    headers: {
      'User-Agent': userAgent,
      Accept: 'application/json',
    },
  });
  const d = response.data;
  if (!d || typeof d !== 'object') return null;
  return {
    author: d.author_name || null,
    thumbnailUrl: d.thumbnail_url || null,
    title: d.title || null,
  };
}

async function fetchOembedMetadata(pageUrl, userAgent) {
  try {
    const fb = await fetchOembedFromEndpoint(
      'https://graph.facebook.com/v18.0/instagram_oembed',
      pageUrl,
      userAgent,
    );
    if (fb) return fb;
  } catch (_) {
    // fallback below
  }

  try {
    return await fetchOembedFromEndpoint(
      'https://api.instagram.com/oembed',
      pageUrl,
      userAgent,
    );
  } catch (_) {
    return null;
  }
}

async function fetchProfileWebInfo(username, userAgent) {
  const url = `https://www.instagram.com/api/v1/users/web_profile_info/?username=${encodeURIComponent(username)}`;
  const referer = `https://www.instagram.com/${username}/`;

  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      const { jar, wwwClaim } = await fetchSessionCookies(userAgent);
      const csrf = jar.csrftoken || '';
      const response = await igHttp.get(url, {
        timeout: REQUEST_TIMEOUT,
        maxRedirects: MAX_REDIRECTS,
        validateStatus: (s) => s >= 200 && s < 500,
        headers: {
          'User-Agent': userAgent,
          Accept: 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
          'x-ig-app-id': '936619743392459',
          'x-requested-with': 'XMLHttpRequest',
          'X-ASBD-ID': '129477',
          'X-IG-WWW-Claim': wwwClaim || '0',
          ...(csrf ? { 'X-CSRFToken': csrf } : {}),
          Referer: referer,
          ...(cookieHeader(jar) ? { Cookie: cookieHeader(jar) } : {}),
        },
      });
      if (response.status === 429 && attempt < 2) {
        await new Promise((r) => setTimeout(r, 2500));
        continue;
      }
      if (response.status >= 200 && response.status < 400) {
        return response.data?.data?.user || null;
      }
      return null;
    } catch (_) {
      if (attempt < 2) {
        await new Promise((r) => setTimeout(r, 1500));
      }
    }
  }
  return null;
}

module.exports = {
  USER_AGENTS,
  REQUEST_TIMEOUT,
  MAX_REDIRECTS,
  parseCookieJar,
  cookieHeader,
  fetchHtml,
  fetchHtmlSources,
  fetchGraphqlVideoUrl,
  fetchOembedMetadata,
  fetchProfileWebInfo,
  fetchSessionCookies,
};
