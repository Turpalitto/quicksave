const config = require('../config');
const { resolveCache } = require('./resolveCache');
const { recordResolve, recordCacheHit, recordCacheMiss } = require('./resolveMetrics');
const { buildCollectionResponse } = require('./mediaCollection');
const {
  normalizeUrl,
  isValidPublicUrl,
  extractShortcode,
  getUrlKind,
  buildEmbedUrl,
} = require('./urlNormalizer');
const {
  extractMetaTags,
  extractAuthor,
  extractVideoFromHtml,
  extractImageFromHtml,
  extractBestFromVideoVersions,
} = require('./postExtractor');
const {
  extractCollectionFromHtml,
  extractCollectionFromGraphql,
  collectionTypeForKind,
} = require('./storyExtractor');
const {
  USER_AGENTS,
  fetchHtmlSources,
  fetchGraphqlVideoUrl,
  fetchOembedMetadata,
} = require('./upstreamClient');
const {
  enrichCollectionWithOembed,
  buildSuccessResult,
  buildImageSuccessResult,
} = require('./resultAssembler');
const { isLoginWall } = require('./resolverErrors');
const { checkLoginWall } = require('./profileExtractorFacade');
const { runSpareResolveStrategies } = require('./resolverSpareStrategies');
const { fetchGraphqlShortcodeMedia } = require('./graphqlShortcodeClient');

function isLoginWallHtml(html) {
  return isLoginWall(html, !!extractVideoFromHtml(html));
}

async function resolveInstagramUrl(inputUrl, options = {}) {
  const url = normalizeUrl(inputUrl);

  if (!isValidPublicUrl(url)) {
    if (require('./profileExtractor').isProfileUrl(url)) {
      return { ok: false, error: 'profile_not_supported' };
    }
    return { ok: false, error: 'invalid_url' };
  }

  const cacheKey = options.cursor ? `${url}?cursor=${options.cursor}` : url;
  if (config.nodeEnv !== 'test') {
    const cached = await resolveCache.get(cacheKey);
    if (cached) {
      recordCacheHit();
      return cached;
    }
    recordCacheMiss();
  }

  const runResolve = async () => {
    if (getUrlKind(url) === 'profile') {
      return { ok: false, error: 'profile_not_supported' };
    }

    const shortcode = extractShortcode(url);
    const urlKind = getUrlKind(url);
    const embedUrl = buildEmbedUrl(url);

    // GraphQL shortcode query (works when HTML no longer embeds video_versions).
    if (shortcode && urlKind !== 'story' && urlKind !== 'highlight') {
      for (const ua of USER_AGENTS.slice(0, 3)) {
        const gqlMedia = await fetchGraphqlShortcodeMedia(url, shortcode, ua);
        if (gqlMedia.videoUrl) {
          let result = buildSuccessResult(
            { videoUrl: gqlMedia.videoUrl, thumbnailUrl: gqlMedia.thumbnailUrl },
            gqlMedia.pageHtml || null,
            shortcode,
            { thumbnailUrl: gqlMedia.thumbnailUrl },
          );
          const oembed = await fetchOembedMetadata(url, ua);
          result = enrichCollectionWithOembed(result, oembed);
          return result;
        }
        const mediaNode =
          gqlMedia.rawData?.data?.xdt_shortcode_media ||
          gqlMedia.rawData?.data?.xdt_api__v1__media__shortcode__web_info?.items?.[0];
        if (mediaNode && mediaNode.is_video === false && mediaNode.display_url) {
          let result = buildImageSuccessResult(mediaNode.display_url, null, shortcode, {
            thumbnailUrl: mediaNode.thumbnail_src || mediaNode.display_url,
          });
          const oembed = await fetchOembedMetadata(url, ua);
          result = enrichCollectionWithOembed(result, oembed);
          return result;
        }
      }
    }

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

      const html = item.res.data && typeof item.res.data === 'string' ? item.res.data : '';
      if (html.length === 0) continue;
      gotNonEmptyHtml = true;
      if (html.length > bestHtml.length) bestHtml = html;

      if (checkLoginWall(html)) sawLoginWall = true;

      const collection = extractCollectionFromHtml(html, shortcode, urlKind);
      if (collection.length > bestCollection.length) {
        bestCollection = collection;
      }

      if (collection.length >= 1 && (urlKind === 'story' || urlKind === 'highlight')) {
        const meta = extractMetaTags(html);
        const type = collectionTypeForKind(urlKind, collection.length);
        let result = buildCollectionResponse(type, collection, {
          author: extractAuthor(meta.title),
          shortcode,
        });
        const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
        result = enrichCollectionWithOembed(result, oembed);
        return result;
      }

      if (collection.length > 1) {
        const meta = extractMetaTags(html);
        const type = collectionTypeForKind(urlKind, collection.length);
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
      const type = collectionTypeForKind(urlKind, bestCollection.length);
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
      if (gqlItems.length > 0) {
        const type = collectionTypeForKind(urlKind, gqlItems.length);
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
        { thumbnailUrl: gqlResult.thumbnailUrl },
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

    if (bestCollection.length >= 1 && (urlKind === 'story' || urlKind === 'highlight')) {
      const meta = bestHtml ? extractMetaTags(bestHtml) : {};
      const type = collectionTypeForKind(urlKind, bestCollection.length);
      let result = buildCollectionResponse(type, bestCollection, {
        author: extractAuthor(meta.title),
        shortcode,
      });
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0]);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }

    if (bestCollection.length === 1) {
      const type = collectionTypeForKind(urlKind, bestCollection.length);
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

    const spare = await runSpareResolveStrategies({
      url,
      shortcode,
      urlKind,
      bestHtml,
      embedUrl,
    });
    if (spare) return spare;

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
    deadlineTimer = setTimeout(() => resolve({ ok: false, error: 'resolver_failed' }), deadline);
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
  isProfileUrl: require('./profileExtractor').isProfileUrl,
  normalizeUrl,
  extractShortcode,
  getUrlKind,
  buildEmbedUrl,
  extractVideoFromHtml,
  extractBestFromVideoVersions,
  isLoginWall: isLoginWallHtml,
};
