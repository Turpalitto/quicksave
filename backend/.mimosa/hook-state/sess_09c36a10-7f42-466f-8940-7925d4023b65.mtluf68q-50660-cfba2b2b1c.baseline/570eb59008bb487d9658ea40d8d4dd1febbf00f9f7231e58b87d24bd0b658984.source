const {
  isProfileUrl,
  extractUsernameFromUrl,
  extractProfileFromHtml,
  dedupeProfileItems,
  timelineNodeToItem,
} = require('./profileExtractor');

describe('profileExtractor', () => {
  test('isProfileUrl accepts username profile', () => {
    expect(isProfileUrl('https://instagram.com/natgeo')).toBe(true);
    expect(isProfileUrl('https://instagram.com/reel/ABC')).toBe(false);
    expect(isProfileUrl('https://instagram.com/explore')).toBe(false);
  });

  test('extractUsernameFromUrl', () => {
    expect(extractUsernameFromUrl('https://instagram.com/natgeo')).toBe('natgeo');
  });

  test('extractProfileFromHtml parses timeline edges', () => {
    const html =
      '"edge_owner_to_timeline_media":{"edges":[' +
      '{"node":{"shortcode":"ABC123","is_video":true,"video_versions":[{"url":"https://cdn.example.com/v.mp4","width":720}],"thumbnail_src":"https://cdn.example.com/t.jpg"}},' +
      '{"node":{"shortcode":"DEF456","is_video":false,"image_versions2":{"candidates":[{"url":"https://cdn.example.com/p.jpg","width":640}]}}}' +
      ']}';
    const { items, author } = extractProfileFromHtml(html, 'natgeo');
    expect(items.length).toBe(2);
    expect(items[0].shortcode).toBe('ABC123');
    expect(items[0].mediaUrl).toContain('.mp4');
    expect(items[1].mediaType).toBe('image');
    expect(items[0].postUrl).toBe('https://www.instagram.com/reel/ABC123');
  });

  test('dedupeProfileItems removes duplicates', () => {
    const items = [
      { id: 'a', index: 0 },
      { id: 'a', index: 1 },
      { id: 'b', index: 2 },
    ];
    expect(dedupeProfileItems(items).length).toBe(2);
  });
});
