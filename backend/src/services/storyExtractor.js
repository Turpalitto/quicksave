const {
  extractCarouselFromHtml,
  extractStoriesFromHtml,
  findCarouselInJson,
  findStoriesInJson,
  itemsFromJsonNodes,
} = require('./mediaCollection');

function extractCollectionFromHtml(html, idPrefix, urlKind) {
  if (urlKind === 'story' || urlKind === 'highlight') {
    return extractStoriesFromHtml(html, idPrefix);
  }
  return extractCarouselFromHtml(html, idPrefix);
}

function extractCollectionFromGraphql(data, idPrefix, urlKind) {
  if (!data || typeof data !== 'object') return [];
  const nodes = urlKind === 'story' || urlKind === 'highlight'
    ? findStoriesInJson(data)
    : findCarouselInJson(data);
  return itemsFromJsonNodes(nodes, idPrefix);
}

function collectionTypeForKind(urlKind, itemCount) {
  if (urlKind === 'story') return 'story';
  if (urlKind === 'highlight') return 'highlight';
  if (itemCount > 1) return 'carousel';
  return 'single';
}

module.exports = {
  extractCollectionFromHtml,
  extractCollectionFromGraphql,
  collectionTypeForKind,
};
