const { unescapeJsonString } = require('./htmlParseUtils');

function safeMatch(text, regex, group = 1) {
  const m = text && text.match(regex);
  return m && m[group] ? m[group] : null;
}

function extractMetaTags(html) {
  const get = (property) => {
    const re1 = new RegExp(
      `<meta[^>]+property=["']${property}["'][^>]*content=["']([^"']+)["']`,
      'i',
    );
    const m1 = html.match(re1);
    if (m1) return m1[1];
    const re2 = new RegExp(
      `<meta[^>]+content=["']([^"']+)["'][^>]*property=["']${property}["']`,
      'i',
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
    /<meta[^>]+property=["']video:duration["'][^>]*content=["'](\d+(?:\.\d+)?)["']/i,
  );
  if (metaMatch) return Math.round(parseFloat(metaMatch[1]));
  const jsonMatch = html.match(/"video_duration"\s*:\s*(\d+(?:\.\d+)?)/);
  if (jsonMatch) return Math.round(parseFloat(jsonMatch[1]));
  return 0;
}

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
        const node =
          obj && obj['@graph'] && Array.isArray(obj['@graph'])
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
    const thumb =
      safeMatch(
        html,
        /"image_versions2"\s*:\s*\{[^}]*"candidates"\s*:\s*\[\s*\{[^\}]*?"url"\s*:\s*"([^"]+)"/,
      ) || safeMatch(html, /"image_versions"\s*:\s*\[\s*\{[^\}]*?"url"\s*:\s*"([^"]+)"/);
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

  const xdtMatch = html.match(
    /"xdt_api__v1__media__shortcode__web_info"[\s\S]{0,8000}?"video_versions"\s*:\s*(\[[\s\S]*?\])/,
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

function extractImageFromHtml(html) {
  if (!html) return null;
  const meta = extractMetaTags(html);
  if (meta.video || meta.videoSecure || meta.videoUrl) return null;
  if (meta.image && /^https?:\/\//i.test(meta.image)) {
    return unescapeJsonString(meta.image);
  }
  const imgMatch =
    safeMatch(
      html,
      /"image_versions2"\s*:\s*\{[^}]*"candidates"\s*:\s*\[\s*\{[^\}]*?"url"\s*:\s*"([^"]+)"/,
    ) || safeMatch(html, /"display_url"\s*:\s*"([^"]+)"/);
  return imgMatch ? unescapeJsonString(imgMatch) : null;
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

module.exports = {
  safeMatch,
  extractMetaTags,
  extractAuthor,
  extractDuration,
  pickBestVideoUrl,
  extractBestFromVideoVersions,
  extractVideoFromHtml,
  extractImageFromHtml,
  findVideoUrlInJson,
  findThumbnailInJson,
  extractVideoQualitiesFromHtml,
};
