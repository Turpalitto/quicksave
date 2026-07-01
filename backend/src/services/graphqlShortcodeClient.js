const igHttp = require('../utils/instagramHttp');
const { findVideoUrlInJson, findThumbnailInJson, extractVideoFromJsonScripts, extractVideoFromHtml } = require('./postExtractor');
const { shortcodeToPk } = require('../utils/shortcodePk');
const {
  cookieHeader,
  parseSetCookieHeaders,
  applyWwwClaimFromResponse,
  createSessionState,
} = require('./instagramSession');

/** yt-dlp / Relay persisted query (2025–2026) — highest success rate for public reels. */
const PRIMARY_DOC_ID = '8845758582119845';

const SHORTCODE_DOC_IDS = [
  PRIMARY_DOC_ID,
  '24368985919464652',
  '10015901848480474',
  '25981206651899035',
  '2315895868520643799',
  '17852401323162214',
];

const IG_APP_ID = '936619743392459';
const IG_ASBD_ID = '198387';

const GRAPHQL_VARIABLES_TEMPLATES = [
  (shortcode) => ({ shortcode }),
  (shortcode) => ({
    shortcode,
    fetch_tagged_user_count: null,
    hoisted_comment_id: null,
    hoisted_reply_id: null,
  }),
  (shortcode) => ({
    shortcode,
    child_comment_count: 3,
    fetch_comment_count: 40,
    parent_comment_count: 24,
    has_threaded_comments: true,
  }),
];

function extractLsdToken(html) {
  if (!html || typeof html !== 'string') return '';
  return (
    html.match(/"LSD",\[\],\{"token":"([^"]+)"\}/)?.[1] ||
    html.match(/"lsd":"([^"]+)"/)?.[1] ||
    ''
  );
}

function extractDocIdFromHtml(html) {
  if (!html || typeof html !== 'string') return null;
  const m = html.match(/"doc_id"\s*:\s*"(\d{15,20})"/);
  return m ? m[1] : null;
}

function parseCookieJar(setCookieHeaders, jar = {}) {
  return parseSetCookieHeaders(setCookieHeaders, jar);
}

function apiHeaders({ userAgent, csrf, lsd, referer, jar, wwwClaim }) {
  return {
    'User-Agent': userAgent,
    Accept: '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'X-IG-App-ID': IG_APP_ID,
    'X-ASBD-ID': IG_ASBD_ID,
    'X-IG-WWW-Claim': wwwClaim || '0',
    Origin: 'https://www.instagram.com',
    'X-Requested-With': 'XMLHttpRequest',
    Referer: referer,
    ...(csrf ? { 'X-CSRFToken': csrf } : {}),
    ...(lsd ? { 'X-FB-LSD': lsd } : {}),
    ...(cookieHeader(jar) ? { Cookie: cookieHeader(jar) } : {}),
  };
}

function parseGraphqlMedia(data) {
  if (!data || typeof data !== 'object') {
    return { videoUrl: null, thumbnailUrl: null, rawData: null };
  }

  const media =
    data.data?.xdt_shortcode_media ||
    data.data?.xdt_api__v1__media__shortcode__web_info?.items?.[0] ||
    data.data?.shortcode_media ||
    null;

  const videoUrl =
    media?.video_url || findVideoUrlInJson(data) || null;
  const thumbnailUrl =
    media?.thumbnail_src ||
    media?.display_url ||
    findThumbnailInJson(data) ||
    null;

  return { videoUrl, thumbnailUrl, rawData: data };
}

function resultFromHtml(html) {
  const fromScripts = extractVideoFromJsonScripts(html);
  if (fromScripts?.videoUrl) {
    return { ...fromScripts, rawData: null, pageHtml: html };
  }
  const fromHtml = extractVideoFromHtml(html);
  if (fromHtml?.videoUrl) {
    return { ...fromHtml, rawData: null, pageHtml: html };
  }
  return null;
}

async function bootstrapSession(userAgent, pageUrl) {
  const session = createSessionState();
  const jar = session.jar;
  let html = '';

  try {
    const home = await igHttp.get('https://www.instagram.com/', {
      timeout: 15000,
      maxRedirects: 5,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en-US,en;q=0.9',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        ...(cookieHeader(jar) ? { Cookie: cookieHeader(jar) } : {}),
      },
    });
    parseCookieJar(home.headers['set-cookie'], jar);
    applyWwwClaimFromResponse(home.headers, session);
  } catch (_) {}

  try {
    const pageRes = await igHttp.get(pageUrl, {
      timeout: 15000,
      maxRedirects: 5,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en-US,en;q=0.9',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        Referer: 'https://www.instagram.com/',
        ...(cookieHeader(jar) ? { Cookie: cookieHeader(jar) } : {}),
      },
    });
    parseCookieJar(pageRes.headers['set-cookie'], jar);
    applyWwwClaimFromResponse(pageRes.headers, session);
    html = typeof pageRes.data === 'string' ? pageRes.data : '';
  } catch (_) {}

  const csrf = jar.csrftoken || '';
  const lsd = extractLsdToken(html);

  return { jar, html, csrf, lsd, wwwClaim: session.wwwClaim };
}

async function warmupRuling(shortcode, userAgent, session, csrf) {
  const pk = shortcodeToPk(shortcode);
  if (!pk) return;
  const { jar } = session;
  try {
    const res = await igHttp.get(
      'https://www.instagram.com/api/v1/web/get_ruling_for_content/',
      {
        params: { content_type: 'MEDIA', target_id: pk },
        timeout: 10000,
        validateStatus: (s) => s >= 200 && s < 500,
        headers: apiHeaders({
          userAgent,
          csrf,
          lsd: '',
          referer: 'https://www.instagram.com/',
          jar,
          wwwClaim: session.wwwClaim,
        }),
      },
    );
    applyWwwClaimFromResponse(res.headers, session);
  } catch (_) {}
}

async function fetchGraphqlGet(userAgent, session, csrf, lsd, pageUrl, docId, variables) {
  const { jar } = session;
  const response = await igHttp.get('https://www.instagram.com/graphql/query/', {
    timeout: 15000,
    validateStatus: (s) => s >= 200 && s < 500,
    headers: apiHeaders({
      userAgent,
      csrf,
      lsd,
      referer: pageUrl,
      jar,
      wwwClaim: session.wwwClaim,
    }),
    params: {
      doc_id: docId,
      variables: JSON.stringify(variables),
    },
  });
  applyWwwClaimFromResponse(response.headers, session);
  return parseGraphqlMedia(response.data);
}

async function fetchGraphqlPost(userAgent, session, csrf, lsd, pageUrl, docId, variables) {
  const { jar } = session;
  const vars = encodeURIComponent(JSON.stringify(variables));
  const body = `variables=${vars}&doc_id=${docId}&server_timestamps=true&lsd=${encodeURIComponent(lsd)}`;

  const response = await igHttp.post(
    'https://www.instagram.com/graphql/query',
    body,
    {
      timeout: 15000,
      validateStatus: (s) => s >= 200 && s < 500,
      headers: {
        ...apiHeaders({
          userAgent,
          csrf,
          lsd,
          referer: pageUrl,
          jar,
          wwwClaim: session.wwwClaim,
        }),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    },
  );
  applyWwwClaimFromResponse(response.headers, session);
  return parseGraphqlMedia(response.data);
}

async function fetchMobileMediaInfo(shortcode, userAgent, session, csrf) {
  const pk = shortcodeToPk(shortcode);
  if (!pk) return { videoUrl: null, thumbnailUrl: null, rawData: null };
  const { jar } = session;

  try {
    const response = await igHttp.get(
      `https://i.instagram.com/api/v1/media/${pk}/info/`,
      {
        timeout: 15000,
        validateStatus: (s) => s >= 200 && s < 500,
        headers: apiHeaders({
          userAgent,
          csrf,
          lsd: '',
          referer: 'https://www.instagram.com/',
          jar,
          wwwClaim: session.wwwClaim,
        }),
      },
    );
    applyWwwClaimFromResponse(response.headers, session);
    const item = response.data?.items?.[0] || response.data;
    if (item && typeof item === 'object') {
      return {
        videoUrl: findVideoUrlInJson(item),
        thumbnailUrl: findThumbnailInJson(item),
        rawData: item,
      };
    }
  } catch (_) {}

  return { videoUrl: null, thumbnailUrl: null, rawData: null };
}

async function fetchEmbedPage(pageUrl, userAgent, jar) {
  const embedUrl = pageUrl.replace(/\/$/, '') + '/embed/';
  try {
    const res = await igHttp.get(embedUrl, {
      timeout: 15000,
      maxRedirects: 5,
      validateStatus: (s) => s >= 200 && s < 400,
      headers: {
        'User-Agent': userAgent,
        'Accept-Language': 'en-US,en;q=0.9',
        Accept:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        Referer: 'https://www.instagram.com/',
        ...(cookieHeader(jar) ? { Cookie: cookieHeader(jar) } : {}),
      },
    });
    const html = typeof res.data === 'string' ? res.data : '';
    return resultFromHtml(html);
  } catch (_) {
    return null;
  }
}

/**
 * Multi-strategy shortcode resolver (yt-dlp / instaloader patterns).
 * Returns { videoUrl, thumbnailUrl, rawData } or empty on failure.
 */
async function fetchGraphqlShortcodeMedia(pageUrl, shortcode, userAgent) {
  const { jar, html, csrf, lsd, wwwClaim } = await bootstrapSession(userAgent, pageUrl);
  const session = { jar, wwwClaim };

  const htmlResult = resultFromHtml(html);
  if (htmlResult?.videoUrl) return htmlResult;

  await warmupRuling(shortcode, userAgent, session, csrf);

  const htmlDocId = extractDocIdFromHtml(html);
  const docIds = htmlDocId
    ? [htmlDocId, ...SHORTCODE_DOC_IDS.filter((id) => id !== htmlDocId)]
    : [...SHORTCODE_DOC_IDS];

  for (const makeVars of GRAPHQL_VARIABLES_TEMPLATES) {
    const variables = makeVars(shortcode);
    for (const docId of docIds) {
      try {
        const getResult = await fetchGraphqlGet(
          userAgent,
          session,
          csrf,
          lsd,
          pageUrl,
          docId,
          variables,
        );
        if (getResult.videoUrl) return getResult;
      } catch (_) {}

      try {
        const postResult = await fetchGraphqlPost(
          userAgent,
          session,
          csrf,
          lsd,
          pageUrl,
          docId,
          variables,
        );
        if (postResult.videoUrl) return postResult;
      } catch (_) {}
    }
  }

  const mobile = await fetchMobileMediaInfo(shortcode, userAgent, session, csrf);
  if (mobile.videoUrl) return mobile;

  const embed = await fetchEmbedPage(pageUrl, userAgent, jar);
  if (embed?.videoUrl) return embed;

  return { videoUrl: null, thumbnailUrl: null, rawData: null };
}

module.exports = {
  fetchGraphqlShortcodeMedia,
  extractLsdToken,
  extractDocIdFromHtml,
  SHORTCODE_DOC_IDS,
  PRIMARY_DOC_ID,
};
