const axios = require('axios');
const config = require('../config');
const { findVideoUrlInJson, findThumbnailInJson } = require('./postExtractor');

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

async function fetchHtml(url, userAgent, maxAttempts = 2) {
  let lastError;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await axios.get(url, {
        timeout: REQUEST_TIMEOUT,
        maxRedirects: MAX_REDIRECTS,
        validateStatus: (s) => s >= 200 && s < 400,
        headers: {
          'User-Agent': userAgent,
          'Accept-Language': 'en-US,en;q=0.9',
          Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          Referer: 'https://www.instagram.com/',
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
  const jobs = [];
  for (const ua of USER_AGENTS) {
    jobs.push({ source: 'page', ua, url: pageUrl, attempts: 2 });
    jobs.push({ source: 'embed', ua, url: embedUrl, attempts: 1 });
  }

  const poolSize = Math.max(1, config.upstreamPoolSize);
  const results = new Array(jobs.length);
  let nextJob = 0;

  async function worker() {
    while (nextJob < jobs.length) {
      const idx = nextJob++;
      const job = jobs[idx];
      try {
        const res = await fetchHtml(job.url, job.ua, job.attempts);
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
  const gqlUrl = `${pageUrl}?__a=1&__d=dis`;
  try {
    const response = await axios.get(gqlUrl, {
      timeout: REQUEST_TIMEOUT,
      maxRedirects: MAX_REDIRECTS,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        Accept: 'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
        'x-ig-app-id': '936619743392459',
        Referer: pageUrl,
      },
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
    if (parsed && typeof parsed === 'object') {
      return {
        videoUrl: findVideoUrlInJson(parsed),
        thumbnailUrl: findThumbnailInJson(parsed),
        rawData: parsed,
      };
    }
    return { videoUrl: null, thumbnailUrl: null, rawData: null };
  } catch (err) {
    const status = err && err.response && err.response.status;
    if (status === 404) {
      const e = new Error('not_found');
      e.code = 'not_found';
      throw e;
    }
    return { videoUrl: null, thumbnailUrl: null, rawData: null };
  }
}

async function fetchOembedMetadata(pageUrl, userAgent) {
  try {
    const response = await axios.get('https://api.instagram.com/oembed', {
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
  } catch (_) {
    return null;
  }
}

async function fetchProfileWebInfo(username, userAgent) {
  const url = `https://www.instagram.com/api/v1/users/web_profile_info/?username=${encodeURIComponent(username)}`;
  try {
    const response = await axios.get(url, {
      timeout: REQUEST_TIMEOUT,
      maxRedirects: MAX_REDIRECTS,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        Accept: 'application/json',
        'Accept-Language': 'en-US,en;q=0.9',
        'x-ig-app-id': '936619743392459',
        'x-requested-with': 'XMLHttpRequest',
        Referer: `https://www.instagram.com/${username}/`,
      },
    });
    return response.data?.data?.user || null;
  } catch (_) {
    return null;
  }
}

module.exports = {
  USER_AGENTS,
  REQUEST_TIMEOUT,
  MAX_REDIRECTS,
  fetchHtml,
  fetchHtmlSources,
  fetchGraphqlVideoUrl,
  fetchOembedMetadata,
  fetchProfileWebInfo,
};
