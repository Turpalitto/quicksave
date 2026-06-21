const { buildCollectionResponse } = require('./mediaCollection');
const {
  extractMetaTags,
  extractAuthor,
  extractDuration,
  extractVideoQualitiesFromHtml,
} = require('./postExtractor');

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

module.exports = {
  enrichCollectionWithOembed,
  buildSuccessResult,
  buildImageSuccessResult,
};
