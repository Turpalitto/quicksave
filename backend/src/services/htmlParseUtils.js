/**
 * Shared HTML/JSON parsing helpers for Instagram scrapers.
 */

function unescapeJsonString(s) {
  if (!s) return s;
  try {
    return JSON.parse('"' + s + '"');
  } catch (_) {
    return s.replace(/\\\//g, '/').replace(/\\\\/g, '\\');
  }
}

function extractBalancedJson(html, startIdx, openChar, closeChar) {
  let depth = 0;
  for (let i = startIdx; i < html.length; i++) {
    const c = html[i];
    if (c === openChar) depth++;
    else if (c === closeChar) {
      depth--;
      if (depth === 0) return html.slice(startIdx, i + 1);
    }
  }
  return null;
}

function tryParseJson(raw) {
  if (!raw) return null;
  try {
    return JSON.parse(raw.replace(/\\\//g, '/'));
  } catch (_) {
    return null;
  }
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

function safeMatch(text, regex, group = 1) {
  const m = text && text.match(regex);
  return m && m[group] ? m[group] : null;
}

module.exports = {
  unescapeJsonString,
  extractBalancedJson,
  tryParseJson,
  pickBestVideoUrl,
  safeMatch,
};
