/**
 * Извлечение коллекций медиа: карусели, stories, highlights.
 */

const {
  unescapeJsonString,
  extractBalancedJson,
  tryParseJson,
  pickBestVideoUrl,
} = require('./htmlParseUtils');

function pickBestImageUrl(node) {
  if (node?.image_versions2?.candidates?.length) {
    const best = node.image_versions2.candidates.reduce((a, b) => {
      const sa = (a.width || 0) * (a.height || 0);
      const sb = (b.width || 0) * (b.height || 0);
      return sb > sa ? b : a;
    });
    if (best?.url) return unescapeJsonString(best.url);
  }
  if (Array.isArray(node?.image_versions) && node.image_versions[0]?.url) {
    return unescapeJsonString(node.image_versions[0].url);
  }
  if (typeof node?.display_url === 'string') {
    return unescapeJsonString(node.display_url);
  }
  if (typeof node?.thumbnail_url === 'string') {
    return unescapeJsonString(node.thumbnail_url);
  }
  return null;
}

function isVideoNode(node) {
  if (!node || typeof node !== 'object') return false;
  if (node.is_video === true) return true;
  if (node.media_type === 2) return true;
  if (node.__typename === 'GraphVideo') return true;
  if (Array.isArray(node.video_versions) && node.video_versions.length > 0) return true;
  if (typeof node.video_url === 'string') return true;
  return false;
}

function mediaNodeToItem(node, index, idPrefix) {
  if (!node || typeof node !== 'object') return null;

  const isVideo = isVideoNode(node);
  let mediaUrl = null;
  let thumbnailUrl = null;
  let duration = 0;
  let width = 0;
  let height = 0;

  if (isVideo) {
    mediaUrl =
      pickBestVideoUrl(node.video_versions) ||
      (node.video_url ? unescapeJsonString(node.video_url) : null) ||
      (node.playable_url ? unescapeJsonString(node.playable_url) : null);
    duration = Math.round(node.video_duration || node.duration || 0);
    const vv = node.video_versions?.[0];
    width = vv?.width || node.original_width || 0;
    height = vv?.height || node.original_height || 0;
    thumbnailUrl = node.thumbnail_url
      ? unescapeJsonString(node.thumbnail_url)
      : pickBestImageUrl(node);
  } else {
    mediaUrl = pickBestImageUrl(node);
    width = node.original_width || node.image_versions2?.candidates?.[0]?.width || 0;
    height = node.original_height || node.image_versions2?.candidates?.[0]?.height || 0;
    thumbnailUrl = mediaUrl;
  }

  if (!mediaUrl || !/^https?:\/\//i.test(mediaUrl)) return null;

  const ext = isVideo ? 'mp4' : 'jpg';
  const fileName = `quicksave_${idPrefix}_${index + 1}.${ext}`;

  return {
    id: `${idPrefix}_${index}`,
    index,
    mediaType: isVideo ? 'video' : 'image',
    mediaUrl,
    thumbnailUrl: thumbnailUrl || mediaUrl,
    duration,
    fileName,
    width,
    height,
  };
}

function nodesFromEdges(edges) {
  if (!Array.isArray(edges)) return [];
  return edges.map((e) => (e && e.node ? e.node : e)).filter(Boolean);
}

/**
 * Извлекает элементы карусели из HTML (carousel_media, edge_sidecar_to_children).
 */
function extractCarouselFromHtml(html, idPrefix) {
  if (!html) return [];

  const markers = [
    '"carousel_media"',
    '"edge_sidecar_to_children"',
    '"xdt_api__v1__media__shortcode__web_info"',
  ];

  let best = [];

  for (const marker of markers) {
    let idx = 0;
    while ((idx = html.indexOf(marker, idx)) !== -1) {
      if (marker === '"edge_sidecar_to_children"') {
        const edgesIdx = html.indexOf('"edges"', idx);
        if (edgesIdx !== -1) {
          const arrStart = html.indexOf('[', edgesIdx);
          const raw = arrStart >= 0 ? extractBalancedJson(html, arrStart, '[', ']') : null;
          const edges = tryParseJson(raw);
          const nodes = nodesFromEdges(edges);
          const items = nodes.map((n, i) => mediaNodeToItem(n, i, idPrefix)).filter(Boolean);
          if (items.length > best.length) best = items;
        }
      } else if (marker === '"carousel_media"') {
        const arrStart = html.indexOf('[', idx);
        const raw = arrStart >= 0 ? extractBalancedJson(html, arrStart, '[', ']') : null;
        const parsed = tryParseJson(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          const items = parsed.map((n, i) => mediaNodeToItem(n, i, idPrefix)).filter(Boolean);
          if (items.length > best.length) best = items;
        }
      } else {
        const carouselIdx = html.indexOf('"carousel_media"', idx);
        if (carouselIdx !== -1) {
          const arrStart = html.indexOf('[', carouselIdx);
          const raw = arrStart >= 0 ? extractBalancedJson(html, arrStart, '[', ']') : null;
          const parsed = tryParseJson(raw);
          if (Array.isArray(parsed) && parsed.length > 0) {
            const items = parsed.map((n, i) => mediaNodeToItem(n, i, idPrefix)).filter(Boolean);
            if (items.length > best.length) best = items;
          }
        }
      }
      idx += marker.length;
    }
  }

  return best;
}

/**
 * Извлекает story / highlight items из HTML.
 */
function extractStoriesFromHtml(html, idPrefix) {
  if (!html) return [];

  const markers = ['"reel_media"', '"items"', '"highlight_reels"'];

  let best = [];

  for (const marker of markers) {
    let idx = 0;
    while ((idx = html.indexOf(marker, idx)) !== -1) {
      const arrStart = html.indexOf('[', idx);
      const raw = arrStart >= 0 ? extractBalancedJson(html, arrStart, '[', ']') : null;
      const parsed = tryParseJson(raw);
      if (!Array.isArray(parsed) || parsed.length === 0) {
        idx += marker.length;
        continue;
      }

      let nodes = parsed;
      if (marker === '"highlight_reels"') {
        nodes = [];
        for (const hr of parsed) {
          if (Array.isArray(hr?.items)) nodes.push(...hr.items);
          else if (hr?.media) nodes.push(hr.media);
          else nodes.push(hr);
        }
      }

      const items = nodes.map((n, i) => mediaNodeToItem(n, i, idPrefix)).filter(Boolean);
      if (items.length > best.length) best = items;
      idx += marker.length;
    }
  }

  // Одиночная story — один video_url / video_versions блок
  if (best.length === 0) {
    const singleVideo = html.match(/"video_versions"\s*:\s*(\[[\s\S]*?\])/);
    if (singleVideo) {
      const versions = tryParseJson(singleVideo[1]);
      const url = pickBestVideoUrl(versions);
      if (url) {
        const thumb = html.match(/"thumbnail_url"\s*:\s*"([^"]+)"/);
        best = [
          {
            id: `${idPrefix}_0`,
            index: 0,
            mediaType: 'video',
            mediaUrl: url,
            thumbnailUrl: thumb ? unescapeJsonString(thumb[1]) : null,
            duration: 0,
            fileName: `quicksave_${idPrefix}_1.mp4`,
            width: 0,
            height: 0,
          },
        ];
      }
    }
  }

  return best;
}

function findCarouselInJson(obj, depth = 0) {
  if (!obj || typeof obj !== 'object' || depth > 12) return [];

  if (Array.isArray(obj.carousel_media) && obj.carousel_media.length > 0) {
    return obj.carousel_media;
  }

  const sidecar = obj.edge_sidecar_to_children?.edges;
  if (Array.isArray(sidecar) && sidecar.length > 0) {
    return nodesFromEdges(sidecar);
  }

  if (Array.isArray(obj)) {
    for (const item of obj) {
      const r = findCarouselInJson(item, depth + 1);
      if (r.length > 0) return r;
    }
    return [];
  }

  for (const k of Object.keys(obj)) {
    const r = findCarouselInJson(obj[k], depth + 1);
    if (r.length > 0) return r;
  }
  return [];
}

function findStoriesInJson(obj, depth = 0) {
  if (!obj || typeof obj !== 'object' || depth > 12) return [];

  if (Array.isArray(obj.items) && obj.items.length > 0 && obj.items[0]?.video_versions) {
    return obj.items;
  }
  if (Array.isArray(obj.reel_media)) return obj.reel_media;

  if (Array.isArray(obj)) {
    for (const item of obj) {
      const r = findStoriesInJson(item, depth + 1);
      if (r.length > 0) return r;
    }
    return [];
  }

  for (const k of Object.keys(obj)) {
    const r = findStoriesInJson(obj[k], depth + 1);
    if (r.length > 0) return r;
  }
  return [];
}

function itemsFromJsonNodes(nodes, idPrefix) {
  return nodes.map((n, i) => mediaNodeToItem(n, i, idPrefix)).filter(Boolean);
}

function buildCollectionResponse(type, items, meta = {}) {
  const videos = items.filter((i) => i.mediaType === 'video');
  const firstVideo = videos[0] || items[0];

  return {
    ok: true,
    type,
    itemCount: items.length,
    videoCount: videos.length,
    imageCount: items.length - videos.length,
    items,
    author: meta.author || null,
    shortcode: meta.shortcode || null,
    videoUrl: firstVideo?.mediaUrl || null,
    thumbnailUrl: firstVideo?.thumbnailUrl || items[0]?.thumbnailUrl || null,
    duration: firstVideo?.duration || 0,
    fileName: firstVideo?.fileName || null,
    quality: 'best',
  };
}

module.exports = {
  mediaNodeToItem,
  extractCarouselFromHtml,
  extractStoriesFromHtml,
  findCarouselInJson,
  findStoriesInJson,
  itemsFromJsonNodes,
  buildCollectionResponse,
  pickBestVideoUrl,
  pickBestImageUrl,
  isVideoNode,
};
