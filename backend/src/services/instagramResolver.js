const axios = require('axios');
const config = require('../config');
const { resolveCache } = require('./resolveCache');
const { recordResolve } = require('./resolveMetrics');
const {
  unescapeJsonString,
} = require('./htmlParseUtils');
const {
  extractCarouselFromHtml,
  extractStoriesFromHtml,
  findCarouselInJson,
  findStoriesInJson,
  itemsFromJsonNodes,
  buildCollectionResponse,
} = require('./mediaCollection');
const {
  isProfileUrl,
  extractUsernameFromUrl,
  extractProfileFromHtml,
  extractProfileFromUserJson,
  dedupeProfileItems,
  fetchProfileFeedPage,
} = require('./profileExtractor');

/**
 * Допустимые паттерны публичных Instagram-постов (после normalizeUrl).
 */
const PUBLIC_PATTERNS = [
  /^https?:\/\/(www\.)?instagram\.com\/(reel|p|tv)\/[A-Za-z0-9_\-]+$/i,
  /^https?:\/\/(www\.)?instagr\.am\/(reel|p|tv)\/[A-Za-z0-9_\-]+$/i,
  /^https?:\/\/(www\.)?instagram\.com\/stories\/[^/]+\/\d+$/i,
  /^https?:\/\/(www\.)?instagram\.com\/stories\/highlights\/\d+$/i,
];

const POST_PATTERNS = PUBLIC_PATTERNS;

const USER_AGENTS = [
  'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 ' +
    '(KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
];

/** Сильные маркеры login wall — без isLoggedIn (есть на всех страницах). */
const LOGIN_WALL_MARKERS = [
  '"Login required"',
  'This account is private',
  'accounts/login',
  'Page Not Found',
  '"login_required"',
  'loginForm',
  'login_page',
];

const REQUEST_TIMEOUT = config.requestTimeoutMs;
const MAX_REDIRECTS = 5;

function isValidPublicUrl(url) {
  const normalized = normalizeUrl(url);
  if (isProfileUrl(normalized)) return true;
  return POST_PATTERNS.some((re) => re.test(normalized));
}

/**
 * Извлекает shortcode / id из канонического URL.
 */
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

/**
 * Строит embed-URL — часто отдаёт видео без login wall.
 */
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

function extractCollectionFromHtml(html, idPrefix, urlKind) {
  if (urlKind === 'story' || urlKind === 'highlight') {
    return extractStoriesFromHtml(html, idPrefix);
  }
  return extractCarouselFromHtml(html, idPrefix);
}

function extractCollectionFromGraphql(data, idPrefix, urlKind) {
  if (!data || typeof data !== 'object') return [];
  const nodes = urlKind === 'story' || urlKind === 'highlight'
    ? findStoriesInJson(data)
    : findCarouselInJson(data);
  return itemsFromJsonNodes(nodes, idPrefix);
}

function enrichCollectionWithOembed(result, oembed) {
  if (!oembed) return result;
  result.author = result.author || oembed.author;
  if (!result.caption && oembed.title) {
    result.caption = oembed.title;
  }
  if (!result.thumbnailUrl && oembed.thumbnailUrl) {
    result.thumbnailUrl = oembed.thumbnailUrl;
  }
  return result;
}

/**
 * Нормализация URL: протокол, алиасы доменов/путей, query/fragment, trailing slash.
 *
 * Поддерживаемые алиасы пути (как у Instagram Share):
 *   /video/reel/ → /reel/
 *   /reels/      → /reel/
 *   /share/reel/ → /reel/
 */
function normalizeUrl(url) {
  let u = url.trim();
  if (!/^https?:\/\//i.test(u)) u = 'https://' + u;

  // instagr.com — частая опечатка в share-тексте → instagram.com
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

  // stories: убираем лишние сегменты после story id
  u = u.replace(
    /instagram\.com\/stories\/([^/]+)\/(\d+)\/[^/]+/gi,
    'instagram.com/stories/$1/$2'
  );

  if (u.endsWith('/')) u = u.slice(0, -1);
  return u;
}

function safeMatch(text, regex, group = 1) {
  const m = text && text.match(regex);
  return m && m[group] ? m[group] : null;
}

function extractImageFromHtml(html) {
  if (!html) return null;
  const meta = extractMetaTags(html);
  if (meta.video || meta.videoSecure || meta.videoUrl) return null;
  if (meta.image && /^https?:\/\//i.test(meta.image)) {
    return unescapeJsonString(meta.image);
  }
  const imgMatch = safeMatch(
    html,
    /"image_versions2"\s*:\s*\{[^}]*"candidates"\s*:\s*\[\s*\{[^\}]*?"url"\s*:\s*"([^"]+)"/
  ) || safeMatch(html, /"display_url"\s*:\s*"([^"]+)"/);
  return imgMatch ? unescapeJsonString(imgMatch) : null;
}

function buildImageSuccessResult(imageUrl, html, shortcode, metaOverride = {}) {
  const meta = html ? extractMetaTags(html) : {};
  const author = metaOverride.author
    || extractAuthor(meta.title)
    || extractAuthor(metaOverride.title)
    || null;
  const item = {
    id: `${shortcode}_0`,
    index: 0,
    mediaType: 'image',
    mediaUrl: imageUrl,
    thumbnailUrl: imageUrl,
    duration: 0,
    fileName: `quicksave_${shortcode}.jpg`,
    width: 0,
    height: 0,
  };
  return buildCollectionResponse('single', [item], { author, shortcode });
}

function extractMetaTags(html) {
  const get = (property) => {
    const re1 = new RegExp(
      `<meta[^>]+property=["']${property}["'][^>]*content=["']([^"']+)["']`,
      'i'
    );
    const m1 = html.match(re1);
    if (m1) return m1[1];
    const re2 = new RegExp(
      `<meta[^>]+content=["']([^"']+)["'][^>]*property=["']${property}["']`,
      'i'
    );
    const m2 = html.match(re2);
    return m2 ? m2[1] : null;
  };
  return {
    video: get('og:video'),
    videoSecure: get('og:video:secure_url'),
    videoUrl: get('og:video:url'),
    image: get('og:image'),
    title: get('og:title'),
  };
}

function extractAuthor(title) {
  if (!title) return null;
  const patterns = [
    /^Reel by\s+(.+?)\s+on/i,
    /^Video by\s+(.+?)\s+on/i,
    /^(.+?)\s+on\s+Instagram/i,
    /^(.+?)\s+•\s+Instagram/i,
  ];
  for (const re of patterns) {
    const m = title.match(re);
    if (m) return m[1].trim();
  }
  return null;
}

function extractDuration(html) {
  const metaMatch = html.match(
    /<meta[^>]+property=["']video:duration["'][^>]*content=["'](\d+(?:\.\d+)?)["']/i
  );
  if (metaMatch) return Math.round(parseFloat(metaMatch[1]));
  const jsonMatch = html.match(/"video_duration"\s*:\s*(\d+(?:\.\d+)?)/);
  if (jsonMatch) return Math.round(parseFloat(jsonMatch[1]));
  return 0;
}

/**
 * Выбирает URL наивысшего качества из массива video_versions.
 */
function pickBestVideoUrl(versions) {
  if (!Array.isArray(versions) || versions.length === 0) return null;
  let best = versions[0];
  for (const v of versions) {
    if (!v || typeof v.url !== 'string') continue;
    const score = (v.width || 0) * (v.height || 0) || v.width || 0;
    const bestScore = (best.width || 0) * (best.height || 0) || best.width || 0;
    if (score > bestScore) best = v;
  }
  return best && best.url ? unescapeJsonString(best.url) : null;
}

/**
 * Ищет все video_versions[] в HTML и возвращает лучший URL.
 */
function extractBestFromVideoVersions(html) {
  const re = /"video_versions"\s*:\s*(\[[\s\S]*?\])/g;
  let match;
  let bestUrl = null;
  let bestScore = -1;

  while ((match = re.exec(html)) !== null) {
    try {
      const raw = match[1].replace(/\\\//g, '/');
      const versions = JSON.parse(raw);
      const url = pickBestVideoUrl(versions);
      if (!url) continue;
      const top = versions.reduce((a, b) => {
        const sa = (a.width || 0) * (a.height || 0);
        const sb = (b.width || 0) * (b.height || 0);
        return sb > sa ? b : a;
      }, versions[0]);
      const score = (top.width || 0) * (top.height || 0);
      if (score > bestScore) {
        bestScore = score;
        bestUrl = url;
      }
    } catch (_) {
      // битый JSON — пробуем regex-fallback
      const urlMatch = match[1].match(/"url"\s*:\s*"([^"]+)"/);
      if (urlMatch) {
        const u = unescapeJsonString(urlMatch[1]);
        if (/^https?:\/\//i.test(u)) bestUrl = u;
      }
    }
  }
  return bestUrl;
}

function extractVideoFromHtml(html) {
  if (!html) return null;

  const meta = extractMetaTags(html);
  const ogVideo = meta.videoSecure || meta.video || meta.videoUrl;
  if (ogVideo) {
    return { videoUrl: ogVideo, thumbnailUrl: meta.image || null };
  }

  const ldRegex = /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let ldMatch;
  while ((ldMatch = ldRegex.exec(html)) !== null) {
    try {
      const ld = JSON.parse(ldMatch[1].trim());
      const objs = Array.isArray(ld) ? ld : [ld];
      for (const obj of objs) {
        const node = obj && obj['@graph'] && Array.isArray(obj['@graph'])
          ? obj['@graph'].find((n) => n && n['@type'] === 'VideoObject')
          : obj;
        if (node && (node.contentUrl || node.embedUrl)) {
          const u = unescapeJsonString(node.contentUrl || node.embedUrl);
          if (/^https?:\/\//i.test(u)) {
            return { videoUrl: u, thumbnailUrl: node.thumbnailUrl || meta.image || null };
          }
        }
      }
    } catch (_) {}
  }

  const videoUrlMatch = html.match(/"video_url"\s*:\s*"([^"]+)"/);
  if (videoUrlMatch) {
    const u = unescapeJsonString(videoUrlMatch[1]);
    if (/^https?:\/\//i.test(u)) {
      const thumb = safeMatch(html, /"thumbnail_url"\s*:\s*"([^"]+)"/);
      return { videoUrl: u, thumbnailUrl: thumb ? unescapeJsonString(thumb) : meta.image || null };
    }
  }

  const bestVersionUrl = extractBestFromVideoVersions(html);
  if (bestVersionUrl) {
    const thumb = safeMatch(html, /"image_versions2"\s*:\s*\{[^}]*"candidates"\s*:\s*\[\s*\{[^\}]*?"url"\s*:\s*"([^"]+)"/)
      || safeMatch(html, /"image_versions"\s*:\s*\[\s*\{[^\}]*?"url"\s*:\s*"([^"]+)"/);
    return {
      videoUrl: bestVersionUrl,
      thumbnailUrl: thumb ? unescapeJsonString(thumb) : meta.image || null,
    };
  }

  const playableMatch = html.match(/"playable_url(_dash)?"\s*:\s*"([^"]+)"/);
  if (playableMatch) {
    const u = unescapeJsonString(playableMatch[2]);
    if (/^https?:\/\//i.test(u)) {
      return { videoUrl: u, thumbnailUrl: meta.image || null };
    }
  }

  // xdt_api / Polaris embedded JSON (современный Instagram)
  const xdtMatch = html.match(
    /"xdt_api__v1__media__shortcode__web_info"[\s\S]{0,8000}?"video_versions"\s*:\s*(\[[\s\S]*?\])/
  );
  if (xdtMatch) {
    try {
      const versions = JSON.parse(xdtMatch[1].replace(/\\\//g, '/'));
      const u = pickBestVideoUrl(versions);
      if (u) return { videoUrl: u, thumbnailUrl: meta.image || null };
    } catch (_) {}
  }

  return null;
}

function isLoginWall(html) {
  if (!html) return false;
  if (extractVideoFromHtml(html)) return false;
  return LOGIN_WALL_MARKERS.some((m) => html.includes(m));
}

function findVideoUrlInJson(obj) {
  if (!obj || typeof obj !== 'object') return null;

  if (Array.isArray(obj)) {
    for (const item of obj) {
      const r = findVideoUrlInJson(item);
      if (r) return r;
    }
    return null;
  }

  if (Array.isArray(obj.video_versions)) {
    const best = pickBestVideoUrl(obj.video_versions);
    if (best) return best;
  }

  const directKeys = ['video_url', 'videoUrl', 'playable_url', 'playable_url_dash', 'contentUrl'];
  for (const k of directKeys) {
    const v = obj[k];
    if (typeof v === 'string' && /^https?:\/\//i.test(v)) {
      return unescapeJsonString(v);
    }
  }

  for (const k of Object.keys(obj)) {
    const r = findVideoUrlInJson(obj[k]);
    if (r) return r;
  }
  return null;
}

function findThumbnailInJson(obj) {
  if (!obj || typeof obj !== 'object') return null;
  if (Array.isArray(obj)) {
    for (const item of obj) {
      const r = findThumbnailInJson(item);
      if (r) return r;
    }
    return null;
  }
  if (typeof obj.thumbnail_url === 'string') return unescapeJsonString(obj.thumbnail_url);
  if (Array.isArray(obj.image_versions2?.candidates) && obj.image_versions2.candidates[0]?.url) {
    return unescapeJsonString(obj.image_versions2.candidates[0].url);
  }
  if (Array.isArray(obj.image_versions) && obj.image_versions[0]?.url) {
    return unescapeJsonString(obj.image_versions[0].url);
  }
  for (const k of Object.keys(obj)) {
    const r = findThumbnailInJson(obj[k]);
    if (r) return r;
  }
  return null;
}

async function fetchGraphqlVideoUrl(pageUrl, userAgent) {
  const gqlUrl = pageUrl + '?__a=1&__d=dis';
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

/**
 * oEmbed — официальный endpoint Instagram для метаданных (автор, превью).
 */
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
          Accept:
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
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

/**
 * Параллельно опрашивает HTML-источники с ограничением concurrency.
 */
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

  await Promise.all(
    Array.from({ length: Math.min(poolSize, jobs.length) }, () => worker())
  );
  return results.filter(Boolean);
}

function extractVideoQualitiesFromHtml(html) {
  if (!html) return [];
  const re = /"video_versions"\s*:\s*(\[[\s\S]*?\])/g;
  let match;
  const all = [];
  while ((match = re.exec(html)) !== null) {
    try {
      const versions = JSON.parse(match[1].replace(/\\\//g, '/'));
      if (!Array.isArray(versions)) continue;
      for (const v of versions) {
        if (!v?.url) continue;
        const w = v.width || 0;
        all.push({
          url: unescapeJsonString(v.url),
          width: w,
          height: v.height || 0,
          label: w >= 720 ? `${w}p` : `${w || 'SD'}p`,
        });
      }
    } catch (_) {}
  }
  const seen = new Set();
  return all.filter((q) => {
    if (seen.has(q.url)) return false;
    seen.add(q.url);
    return true;
  });
}

function buildSuccessResult(extracted, html, shortcode, metaOverride = {}) {
  const meta = html ? extractMetaTags(html) : {};
  const author = metaOverride.author
    || extractAuthor(meta.title)
    || extractAuthor(metaOverride.title)
    || null;
  const qualities = html ? extractVideoQualitiesFromHtml(html) : [];
  const item = {
    id: `${shortcode}_0`,
    index: 0,
    mediaType: 'video',
    mediaUrl: extracted.videoUrl,
    thumbnailUrl: extracted.thumbnailUrl || metaOverride.thumbnailUrl || meta.image || null,
    duration: html ? extractDuration(html) : 0,
    fileName: `quicksave_${shortcode}.mp4`,
    width: 0,
    height: 0,
    ...(qualities.length > 1 ? { qualities } : {}),
  };
  return buildCollectionResponse('single', [item], {
    author,
    shortcode,
  });
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

async function resolveProfileUrl(url, options = {}) {
  const username = extractUsernameFromUrl(url);
  if (!username) return { ok: false, error: 'invalid_url' };

  const { cursor, userId: inputUserId } = options;

  if (cursor && inputUserId) {
    const feed = await fetchProfileFeedPage(
      inputUserId,
      cursor,
      username,
      USER_AGENTS[0],
      REQUEST_TIMEOUT
    );
    const items = dedupeProfileItems(feed.items);
    if (items.length === 0) {
      return { ok: false, error: 'resolver_failed' };
    }
    const result = buildCollectionResponse('profile', items, {
      author: username,
      shortcode: username,
    });
    result.username = username;
    result.userId = String(inputUserId);
    result.nextCursor = feed.nextMaxId || null;
    result.hasMore = feed.moreAvailable && !!feed.nextMaxId;
    return result;
  }

  let sawLoginWall = false;
  let saw404 = false;
  let bestHtml = '';
  let bestItems = [];
  let author = username;

  for (const ua of USER_AGENTS) {
    try {
      const res = await fetchHtml(url.endsWith('/') ? url : `${url}/`, ua, 2);
      const html = typeof res.data === 'string' ? res.data : '';
      if (html.length > bestHtml.length) bestHtml = html;
      if (isLoginWall(html)) sawLoginWall = true;
      const extracted = extractProfileFromHtml(html, username);
      if (extracted.items.length > bestItems.length) {
        bestItems = extracted.items;
        author = extracted.author || author;
      }
    } catch (err) {
      const status = err.response && err.response.status;
      if (status === 404) saw404 = true;
      if (status === 401 || status === 403) sawLoginWall = true;
    }
  }

  const apiUser = await fetchProfileWebInfo(username, USER_AGENTS[0]);
  let pageInfo = null;
  let userId = null;
  if (apiUser) {
    const fromApi = extractProfileFromUserJson(apiUser, username);
    if (fromApi.items.length > bestItems.length) {
      bestItems = fromApi.items;
      author = fromApi.author || author;
    }
    pageInfo = fromApi.pageInfo;
    userId = fromApi.userId;
  }

  bestItems = dedupeProfileItems(bestItems);

  if (bestItems.length > 0) {
    let result = buildCollectionResponse('profile', bestItems, {
      author,
      shortcode: username,
    });
    result.username = username;
    result.userId = userId ? String(userId) : null;
    result.nextCursor = pageInfo?.end_cursor || pageInfo?.endCursor || null;
    result.hasMore = pageInfo?.has_next_page === true || pageInfo?.hasNextPage === true;
    return result;
  }

  if (sawLoginWall) return { ok: false, error: 'private' };
  if (saw404) return { ok: false, error: 'not_found' };
  return { ok: false, error: 'resolver_failed' };
}

/**
 * Резолвит публичный Instagram-пост или профиль.
 *
 * Стратегия (параллельный cascade — быстрее конкурентов с последовательным опросом):
 *   1. Параллельно: основная страница + embed × 4 User-Agent.
 *   2. Параллельно: GraphQL ?__a=1&__d=dis.
 *   3. oEmbed для обогащения метаданных (автор, превью).
 */
async function resolveInstagramUrl(inputUrl, options = {}) {
  const url = normalizeUrl(inputUrl);

  if (!isValidPublicUrl(url)) {
    return { ok: false, error: 'invalid_url' };
  }

  const cacheKey = options.cursor
    ? `${url}?cursor=${options.cursor}`
    : url;
  if (config.nodeEnv !== 'test') {
    const cached = await resolveCache.get(cacheKey);
    if (cached) return cached;
  }

  const runResolve = async () => {
  if (getUrlKind(url) === 'profile') {
    return resolveProfileUrl(url, options);
  }

  const shortcode = extractShortcode(url);
  const urlKind = getUrlKind(url);
  const embedUrl = buildEmbedUrl(url);

  let sawLoginWall = false;
  let saw404 = false;
  let sawHardError = false;
  let lastNetworkError = false;
  let gotNonEmptyHtml = false;
  let bestHtml = '';
  let bestCollection = [];

  const htmlResults = await fetchHtmlSources(url, embedUrl);

  for (const item of htmlResults) {
    if (item.err) {
      const status = item.err.response && item.err.response.status;
      if (status === 404) saw404 = true;
      else if (status === 401 || status === 403) sawLoginWall = true;
      else if (status >= 400) sawHardError = true;
      else if (item.err.code === 'ECONNABORTED' || item.err.code === 'ETIMEDOUT') {
        lastNetworkError = true;
      } else if (!status) lastNetworkError = true;
      continue;
    }

    const html = (item.res.data && typeof item.res.data === 'string') ? item.res.data : '';
    if (html.length === 0) continue;
    gotNonEmptyHtml = true;
    if (html.length > bestHtml.length) bestHtml = html;

    if (isLoginWall(html)) sawLoginWall = true;

    const collection = extractCollectionFromHtml(html, shortcode, urlKind);
    if (collection.length > bestCollection.length) {
      bestCollection = collection;
    }

    if (collection.length > 1) {
      const meta = extractMetaTags(html);
      const type = urlKind === 'story' ? 'story' : urlKind === 'highlight' ? 'highlight' : 'carousel';
      let result = buildCollectionResponse(type, collection, {
        author: extractAuthor(meta.title),
        shortcode,
      });
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }

    const extracted = extractVideoFromHtml(html);
    if (extracted && extracted.videoUrl) {
      let result = buildSuccessResult(extracted, html, shortcode);
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }
  }

  if (bestCollection.length > 1) {
    const meta = bestHtml ? extractMetaTags(bestHtml) : {};
    const type = urlKind === 'story' ? 'story' : urlKind === 'highlight' ? 'highlight' : 'carousel';
    let result = buildCollectionResponse(type, bestCollection, {
      author: extractAuthor(meta.title),
      shortcode,
    });
    const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
    result = enrichCollectionWithOembed(result, oembed);
    return result;
  }

  let gqlResult = { videoUrl: null, thumbnailUrl: null, rawData: null };
  try {
    gqlResult = await fetchGraphqlVideoUrl(url, USER_AGENTS[0]);
  } catch (err) {
    if (err && err.code === 'not_found') {
      if (sawLoginWall) return { ok: false, error: 'private' };
      saw404 = true;
    }
  }

  if (gqlResult.rawData) {
    const gqlItems = extractCollectionFromGraphql(gqlResult.rawData, shortcode, urlKind);
    if (gqlItems.length > 1) {
      const type = urlKind === 'story' ? 'story' : urlKind === 'highlight' ? 'highlight' : 'carousel';
      let result = buildCollectionResponse(type, gqlItems, { shortcode });
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }
    if (gqlItems.length === 1) {
      const type = urlKind === 'story' ? 'story' : 'single';
      let result = buildCollectionResponse(type, gqlItems, { shortcode });
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }
  }

  if (gqlResult.videoUrl) {
    let result = buildSuccessResult(
      { videoUrl: gqlResult.videoUrl, thumbnailUrl: gqlResult.thumbnailUrl },
      null,
      shortcode,
      { thumbnailUrl: gqlResult.thumbnailUrl }
    );
    const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
    result = enrichCollectionWithOembed(result, oembed);
    return result;
  }

  if (bestHtml) {
    const imageUrl = extractImageFromHtml(bestHtml);
    if (imageUrl) {
      let result = buildImageSuccessResult(imageUrl, bestHtml, shortcode);
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }
  }

  if (bestCollection.length === 1) {
    const type = urlKind === 'story' ? 'story' : 'single';
    let result = buildCollectionResponse(type, bestCollection, { shortcode });
    const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
    result = enrichCollectionWithOembed(result, oembed);
    return result;
  }

  if (saw404 && !sawLoginWall && !gotNonEmptyHtml) {
    return { ok: false, error: 'not_found' };
  }
  if (sawLoginWall) {
    return { ok: false, error: 'private' };
  }
  if (lastNetworkError || sawHardError) {
    return { ok: false, error: 'resolver_failed' };
  }
  if (!gotNonEmptyHtml) {
    return { ok: false, error: 'not_found' };
  }
  return { ok: false, error: 'resolver_failed' };
  };

  const deadline = config.resolveDeadlineMs;
  let deadlineTimer;
  const deadlinePromise = new Promise((resolve) => {
    deadlineTimer = setTimeout(
      () => resolve({ ok: false, error: 'resolver_failed' }),
      deadline
    );
  });

  const result = await Promise.race([runResolve(), deadlinePromise]);
  clearTimeout(deadlineTimer);

  recordResolve(result);

  if (result.ok && config.nodeEnv !== 'test') {
    resolveCache.set(cacheKey, result);
  }
  return result;
}

module.exports = {
  resolveInstagramUrl,
  isValidPublicUrl,
  isProfileUrl,
  normalizeUrl,
  extractShortcode,
  getUrlKind,
  buildEmbedUrl,
  extractVideoFromHtml,
  extractBestFromVideoVersions,
  isLoginWall,
};
