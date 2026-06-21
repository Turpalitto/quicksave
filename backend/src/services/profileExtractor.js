/**
 * Извлечение постов из публичного профиля Instagram.
 */

const axios = require('axios');
const { mediaNodeToItem, pickBestImageUrl, isVideoNode } = require('./mediaCollection');
const { unescapeJsonString, extractBalancedJson } = require('./htmlParseUtils');

const RESERVED_USERNAMES = new Set([
  'reel', 'reels', 'p', 'tv', 'stories', 'explore', 'accounts', 'direct',
  'about', 'legal', 'developer', 'privacy', 'terms', 'api', 'static',
  'challenge', 'oauth', 'nametag', 'login', 'directory', 'web', 'help',
  'press', 'jobs', 'graphql', 'email', 'sms', 'sharing', 'lite',
  'download', 'creators', 'blog', 'guides', 'locations', 'session',
]);

function isProfileUrl(url) {
  const m = url.match(/^https?:\/\/(www\.)?instagram\.com\/([^/?#]+)$/i);
  if (!m) return false;
  return !RESERVED_USERNAMES.has(m[2].toLowerCase());
}

function extractUsernameFromUrl(url) {
  const m = url.match(/instagram\.com\/([^/?#]+)/i);
  if (!m) return null;
  const u = m[1];
  if (RESERVED_USERNAMES.has(u.toLowerCase())) return null;
  return u;
}

function nodesFromTimelineEdges(edges) {
  if (!Array.isArray(edges)) return [];
  return edges.map((e) => (e && e.node ? e.node : e)).filter(Boolean);
}

function findTimelineEdges(obj, depth = 0) {
  if (!obj || typeof obj !== 'object' || depth > 14) return [];

  const keys = [
    'edge_owner_to_timeline_media',
    'edge_felix_video_timeline',
  ];

  for (const k of keys) {
    const block = obj[k];
    if (block && Array.isArray(block.edges) && block.edges.length > 0) {
      return block.edges;
    }
  }

  if (Array.isArray(obj)) {
    for (const item of obj) {
      const r = findTimelineEdges(item, depth + 1);
      if (r.length > 0) return r;
    }
    return [];
  }

  for (const k of Object.keys(obj)) {
    const r = findTimelineEdges(obj[k], depth + 1);
    if (r.length > 0) return r;
  }
  return [];
}

function postPathForNode(node) {
  if (node.product_type === 'clips') return 'reel';
  if (node.is_video) return 'reel';
  return 'p';
}

function hasDirectDownloadUrl(url, isVideo) {
  if (!url || !/^https?:\/\//i.test(url)) return false;
  if (isVideo) {
    return url.includes('.mp4') || url.includes('/video/') || url.includes('cdninstagram');
  }
  return url.includes('cdninstagram') || /\.(jpe?g|webp)/i.test(url);
}

function timelineNodeToItem(node, index, username) {
  if (!node || typeof node !== 'object') return null;

  const shortcode = node.shortcode || node.code;
  if (!shortcode) return null;

  const isVideo = isVideoNode(node);
  const path = postPathForNode(node);
  const postUrl = `https://www.instagram.com/${path}/${shortcode}`;

  const fromMedia = mediaNodeToItem(node, index, shortcode);
  const directUrl = fromMedia?.mediaUrl;
  const hasDirect = hasDirectDownloadUrl(directUrl, isVideo);

  const thumb = pickBestImageUrl(node)
    || (node.thumbnail_src ? unescapeJsonString(node.thumbnail_src) : null)
    || fromMedia?.thumbnailUrl;

  if (!hasDirect && !thumb && !isVideo) return null;

  const mediaUrl = hasDirect ? directUrl : (isVideo ? '' : (directUrl || thumb || ''));

  return {
    id: shortcode,
    index,
    mediaType: isVideo ? 'video' : 'image',
    mediaUrl: mediaUrl || '',
    thumbnailUrl: thumb || null,
    duration: fromMedia?.duration || 0,
    fileName: `quicksave_${username}_${shortcode}.${isVideo ? 'mp4' : 'jpg'}`,
    width: fromMedia?.width || node.original_width || 0,
    height: fromMedia?.height || node.original_height || 0,
    postUrl,
    shortcode,
    needsResolve: isVideo ? !hasDirect : !mediaUrl,
  };
}

function findTimelinePageInfo(obj, depth = 0) {
  if (!obj || typeof obj !== 'object' || depth > 14) return null;

  const keys = ['edge_owner_to_timeline_media', 'edge_felix_video_timeline'];
  for (const k of keys) {
    const block = obj[k];
    if (block && block.page_info && typeof block.page_info === 'object') {
      return block.page_info;
    }
  }

  if (Array.isArray(obj)) {
    for (const item of obj) {
      const r = findTimelinePageInfo(item, depth + 1);
      if (r) return r;
    }
    return null;
  }

  for (const k of Object.keys(obj)) {
    const r = findTimelinePageInfo(obj[k], depth + 1);
    if (r) return r;
  }
  return null;
}

function extractBalancedJsonFromHtml(html, startIdx, openChar, closeChar) {
  return extractBalancedJson(html, startIdx, openChar, closeChar);
}

function findTimelineEdgesInHtml(html) {
  if (!html || typeof html !== 'string') return [];

  const markers = ['"edge_owner_to_timeline_media"', '"edge_felix_video_timeline"'];
  for (const marker of markers) {
    let idx = 0;
    while ((idx = html.indexOf(marker, idx)) !== -1) {
      const objStart = html.indexOf('{', idx);
      if (objStart === -1) break;
      const raw = extractBalancedJsonFromHtml(html, objStart, '{', '}');
      if (raw) {
        try {
          const parsed = JSON.parse(raw.replace(/\\\//g, '/'));
          if (Array.isArray(parsed.edges) && parsed.edges.length > 0) {
            return parsed.edges;
          }
        } catch (_) {}
      }
      idx += marker.length;
    }
  }
  return [];
}

function extractProfileFromHtml(html, username) {
  if (!html) return { items: [], author: username };

  const edges = findTimelineEdgesInHtml(html);
  const nodes = nodesFromTimelineEdges(edges);
  const items = nodes
    .map((n, i) => timelineNodeToItem(n, i, username))
    .filter(Boolean);

  let author = username;
  const titleMatch = html.match(
    /<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i
  ) || html.match(
    /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i
  );
  if (titleMatch) {
    const m = titleMatch[1].match(/^(@?\w[\w.]*)/);
    if (m) author = m[1].replace(/^@/, '');
  }

  return { items, author };
}

function extractProfileFromUserJson(user, username) {
  if (!user || typeof user !== 'object') {
    return { items: [], author: username, pageInfo: null, userId: null };
  }

  const edges = findTimelineEdges(user);
  const nodes = nodesFromTimelineEdges(edges);
  const items = nodes
    .map((n, i) => timelineNodeToItem(n, i, username))
    .filter(Boolean);

  return {
    items,
    author: user.username || username,
    pageInfo: findTimelinePageInfo(user),
    userId: user.id || user.pk || null,
  };
}

function extractProfileFromFeedItems(items, username, startIndex = 0) {
  if (!Array.isArray(items)) return [];
  return items
    .map((item, i) => {
      const node = item.media || item;
      return timelineNodeToItem(node, startIndex + i, username);
    })
    .filter(Boolean);
}

async function fetchProfileFeedPage(userId, maxId, username, userAgent, timeout = 15000) {
  if (!userId) return { items: [], nextMaxId: null, moreAvailable: false };

  const params = new URLSearchParams({ count: '12' });
  if (maxId) params.set('max_id', maxId);

  const url = `https://www.instagram.com/api/v1/feed/user/${userId}/?${params.toString()}`;
  try {
    const response = await axios.get(url, {
      timeout,
      maxRedirects: 5,
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
    const data = response.data;
    const rawItems = data?.items || [];
    const items = extractProfileFromFeedItems(rawItems, username);
    return {
      items,
      nextMaxId: data?.next_max_id || null,
      moreAvailable: data?.more_available === true,
    };
  } catch (_) {
    return { items: [], nextMaxId: null, moreAvailable: false };
  }
}

function dedupeProfileItems(items) {
  const seen = new Set();
  const out = [];
  for (const item of items) {
    if (seen.has(item.id)) continue;
    seen.add(item.id);
    out.push({ ...item, index: out.length });
  }
  return out;
}

module.exports = {
  RESERVED_USERNAMES,
  isProfileUrl,
  extractUsernameFromUrl,
  extractProfileFromHtml,
  extractProfileFromUserJson,
  dedupeProfileItems,
  timelineNodeToItem,
  findTimelinePageInfo,
  fetchProfileFeedPage,
  extractProfileFromFeedItems,
};
