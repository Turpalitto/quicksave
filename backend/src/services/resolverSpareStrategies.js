/**
 * Extra resolve fallbacks when primary strategies fail (Instagram layout/API changes).
 * Kept separate so new strategies can be appended without rewriting the main resolver.
 */

const {
  extractMetaTags,
  extractAuthor,
  extractBestFromVideoVersions,
  extractVideoFromHtml,
  extractImageFromHtml,
} = require('./postExtractor');
const { fetchGraphqlShortcodeMedia } = require('./graphqlShortcodeClient');
const { fetchOembedMetadata, fetchHtml, USER_AGENTS } = require('./upstreamClient');
const { buildSuccessResult, buildImageSuccessResult, enrichCollectionWithOembed } = require('./resultAssembler');

async function tryVideoVersionsInHtml(bestHtml, shortcode, url, urlKind) {
  if (!bestHtml || urlKind === 'story' || urlKind === 'highlight') return null;
  const videoUrl = extractBestFromVideoVersions(bestHtml);
  if (!videoUrl) return null;
  let result = buildSuccessResult(
    { videoUrl, thumbnailUrl: extractMetaTags(bestHtml).image },
    bestHtml,
    shortcode,
  );
  const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
  return enrichCollectionWithOembed(result, oembed);
}

async function tryOgMetaInHtml(bestHtml, shortcode, url, urlKind) {
  if (!bestHtml || urlKind === 'story' || urlKind === 'highlight') return null;
  const meta = extractMetaTags(bestHtml);
  const videoUrl = meta.videoSecure || meta.video || meta.videoUrl;
  if (videoUrl) {
    let result = buildSuccessResult(
      { videoUrl, thumbnailUrl: meta.image },
      bestHtml,
      shortcode,
      { author: extractAuthor(meta.title) },
    );
    const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
    return enrichCollectionWithOembed(result, oembed);
  }
  const extracted = extractVideoFromHtml(bestHtml);
  if (extracted?.videoUrl) {
    let result = buildSuccessResult(extracted, bestHtml, shortcode);
    const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
    return enrichCollectionWithOembed(result, oembed);
  }
  return null;
}

async function tryEmbedPage(url, shortcode, embedUrl, urlKind) {
  if (urlKind === 'story' || urlKind === 'highlight') return null;
  for (const ua of USER_AGENTS) {
    try {
      const res = await fetchHtml(embedUrl, ua, 1);
      const html = typeof res.data === 'string' ? res.data : '';
      if (!html) continue;
      const extracted = extractVideoFromHtml(html) || { videoUrl: extractBestFromVideoVersions(html) };
      if (extracted?.videoUrl) {
        let result = buildSuccessResult(extracted, html, shortcode);
        const oembed = await fetchOembedMetadata(url, ua);
        return enrichCollectionWithOembed(result, oembed);
      }
    } catch (_) {}
  }
  return null;
}

async function tryAllUserAgentsGraphql(pageUrl, shortcode, urlKind) {
  if (!shortcode || urlKind === 'story' || urlKind === 'highlight') return null;
  for (const ua of USER_AGENTS) {
    const gqlMedia = await fetchGraphqlShortcodeMedia(pageUrl, shortcode, ua);
    if (gqlMedia.videoUrl) {
      let result = buildSuccessResult(
        { videoUrl: gqlMedia.videoUrl, thumbnailUrl: gqlMedia.thumbnailUrl },
        gqlMedia.pageHtml || null,
        shortcode,
        { thumbnailUrl: gqlMedia.thumbnailUrl },
      );
      const oembed = await fetchOembedMetadata(pageUrl, ua);
      return enrichCollectionWithOembed(result, oembed);
    }
    const mediaNode =
      gqlMedia.rawData?.data?.xdt_shortcode_media ||
      gqlMedia.rawData?.data?.xdt_api__v1__media__shortcode__web_info?.items?.[0];
    if (mediaNode && mediaNode.is_video === false && mediaNode.display_url) {
      let result = buildImageSuccessResult(mediaNode.display_url, null, shortcode, {
        thumbnailUrl: mediaNode.thumbnail_src || mediaNode.display_url,
      });
      const oembed = await fetchOembedMetadata(pageUrl, ua);
      return enrichCollectionWithOembed(result, oembed);
    }
  }
  return null;
}

async function tryImageFallback(bestHtml, shortcode, url, urlKind) {
  if (!bestHtml || urlKind === 'story' || urlKind === 'highlight') return null;
  const imageUrl = extractImageFromHtml(bestHtml);
  if (!imageUrl) return null;
  let result = buildImageSuccessResult(imageUrl, bestHtml, shortcode);
  const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
  return enrichCollectionWithOembed(result, oembed);
}

/**
 * Runs spare strategies in order until one succeeds.
 */
async function runSpareResolveStrategies(ctx) {
  const { url, shortcode, urlKind, bestHtml, embedUrl } = ctx;
  const strategies = [
    () => tryVideoVersionsInHtml(bestHtml, shortcode, url, urlKind),
    () => tryOgMetaInHtml(bestHtml, shortcode, url, urlKind),
    () => tryAllUserAgentsGraphql(url, shortcode, urlKind),
    () => tryEmbedPage(url, shortcode, embedUrl, urlKind),
    () => tryImageFallback(bestHtml, shortcode, url, urlKind),
  ];

  for (const strategy of strategies) {
    try {
      const result = await strategy();
      if (result && result.ok !== false && (result.videoUrl || result.items?.length)) {
        return result;
      }
    } catch (_) {}
  }
  return null;
}

module.exports = {
  runSpareResolveStrategies,
  tryVideoVersionsInHtml,
  tryOgMetaInHtml,
  tryEmbedPage,
  tryAllUserAgentsGraphql,
};
