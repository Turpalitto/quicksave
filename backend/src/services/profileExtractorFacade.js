const { buildCollectionResponse } = require('./mediaCollection');
const {
  isProfileUrl,
  extractUsernameFromUrl,
  extractProfileFromHtml,
  extractProfileFromUserJson,
  dedupeProfileItems,
  fetchProfileFeedPage,
} = require('./profileExtractor');
const { isLoginWall } = require('./resolverErrors');
const { extractVideoFromHtml } = require('./postExtractor');
const {
  USER_AGENTS,
  REQUEST_TIMEOUT,
  fetchHtml,
  fetchProfileWebInfo,
} = require('./upstreamClient');

function checkLoginWall(html) {
  return isLoginWall(html, !!extractVideoFromHtml(html));
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
      if (checkLoginWall(html)) sawLoginWall = true;
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
    const result = buildCollectionResponse('profile', bestItems, {
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

module.exports = {
  isProfileUrl,
  resolveProfileUrl,
  checkLoginWall,
};
