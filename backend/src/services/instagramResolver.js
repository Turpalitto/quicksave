const config = require('../config');
const { resolveCache } = require('./resolveCache');
const { recordResolve, recordCacheHit, recordCacheMiss, recordStaleServed, recordStrategy } =
  require('./resolveMetrics');
const { buildCollectionResponse } = require('./mediaCollection');
const { hashUrl } = require('../utils/urlSanitizer');
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
const { fetchFallbackMedia } = require('./fallbackProvider');

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

  const cacheKey = options.cursor ? `${url}?cursor=${hashUrl(options.cursor)}` : url;
  if (config.nodeEnv !== 'test') {
    const cached = await resolveCache.get(cacheKey);
    if (cached) {
      recordCacheHit();
      return cached;
    }
    recordCacheMiss();
  }

  const runResolve = async (signal) => {
    if (getUrlKind(url) === 'profile') {
      return { ok: false, error: 'profile_not_supported' };
    }

    const shortcode = extractShortcode(url);
    const urlKind = getUrlKind(url);
    const embedUrl = buildEmbedUrl(url);

    // GraphQL shortcode query (works when HTML no longer embeds video_versions).
    if (shortcode && urlKind !== 'story' && urlKind !== 'highlight') {
      for (const ua of USER_AGENTS.slice(0, 3)) {
        const gqlMedia = await fetchGraphqlShortcodeMedia(url, shortcode, ua, signal);
      if (gqlMedia.videoUrl) {
        recordStrategy('graphql_shortcode', true);
        let result = buildSuccessResult(
            { videoUrl: gqlMedia.videoUrl, thumbnailUrl: gqlMedia.thumbnailUrl },
            gqlMedia.pageHtml || null,
            shortcode,
            { thumbnailUrl: gqlMedia.thumbnailUrl },
          );
          const oembed = await fetchOembedMetadata(url, ua, signal);
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
          const oembed = await fetchOembedMetadata(url, ua, signal);
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

    const htmlResults = await fetchHtmlSources(url, embedUrl, signal);

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
        const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
        result = enrichCollectionWithOembed(result, oembed);
        return result;
      }

      if (collection.length > 1) {
        recordStrategy('collections', true);
        const meta = extractMetaTags(html);
        const type = collectionTypeForKind(urlKind, collection.length);
        let result = buildCollectionResponse(type, collection, {
          author: extractAuthor(meta.title),
          shortcode,
        });
        const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
        result = enrichCollectionWithOembed(result, oembed);
        return result;
      }

      const extracted = extractVideoFromHtml(html);
      if (extracted && extracted.videoUrl) {
        recordStrategy('html', true);
        let result = buildSuccessResult(extracted, html, shortcode);
        const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
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
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }

    let gqlResult = { videoUrl: null, thumbnailUrl: null, rawData: null };
    try {
      gqlResult = await fetchGraphqlVideoUrl(url, USER_AGENTS[0], signal);
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
        const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
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
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }

    if (bestHtml) {
      const imageUrl = extractImageFromHtml(bestHtml);
      if (imageUrl) {
        recordStrategy('image', true);
        let result = buildImageSuccessResult(imageUrl, bestHtml, shortcode);
        const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
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
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
      result = enrichCollectionWithOembed(result, oembed);
      return result;
    }

    if (bestCollection.length === 1) {
      const type = collectionTypeForKind(urlKind, bestCollection.length);
      let result = buildCollectionResponse(type, bestCollection, { shortcode });
      const oembed = await fetchOembedMetadata(url, USER_AGENTS[0], signal);
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
      signal,
    });
    if (spare) {
      recordStrategy('spare', true);
      return spare;
    }

    // Paid fallback tier (only when configured): network failures / blocked
    // pages that free strategies could not crack. Private and deleted posts
    // already returned above and must not cost money.
    if (config.fallbackApiUrl && config.fallbackApiKey && (lastNetworkError || sawHardError || gotNonEmptyHtml)) {
      const fallback = await fetchFallbackMedia(url, signal);
      if (fallback) {
        recordStrategy('fallback_api', true);
        return buildSuccessResult(
          { videoUrl: fallback.videoUrl, thumbnailUrl: fallback.thumbnailUrl },
          null,
          shortcode,
          { thumbnailUrl: fallback.thumbnailUrl },
        );
      }
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
  const ac = new AbortController();
  let deadlineTimer;
  const deadlinePromise = new Promise((resolve) => {
    deadlineTimer = setTimeout(() => {
      try {
        ac.abort();
      } catch (_) {}
      resolve({ ok: false, error: 'resolver_failed' });
    }, deadline);
  });

  // Swallow late failures after the deadline has already resolved the race.
  const runPromise = runResolve(ac.signal).catch(() => ({ ok: false, error: 'resolver_failed' }));
  const result = await Promise.race([runPromise, deadlinePromise]);
  clearTimeout(deadlineTimer);

  // Cancel any upstream work still in flight (deadline hit mid-resolve).
  try {
    ac.abort();
  } catch (_) {}

  recordResolve(result);
  if (!result.ok) {
    recordStrategy('chain', false);

    // Stale-while-revalidate: a transient resolver failure is less harmful
    // than serving nothing when we recently resolved this URL successfully.
    if (
      config.nodeEnv !== 'test' &&
      config.staleWhileRevalidate &&
      (result.error === 'resolver_failed' || result.error === 'upstream_timeout')
    ) {
      const stale = await resolveCache.getStale(cacheKey);
      if (stale && stale.ok === true) {
        recordStaleServed();
        return { ...stale, stale: true };
      }
    }
  }

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
