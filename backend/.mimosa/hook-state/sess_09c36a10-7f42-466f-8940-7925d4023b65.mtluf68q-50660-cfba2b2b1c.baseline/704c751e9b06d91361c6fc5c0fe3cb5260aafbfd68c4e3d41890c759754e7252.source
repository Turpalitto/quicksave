const {
  mediaNodeToItem,
  extractCarouselFromHtml,
  extractStoriesFromHtml,
  buildCollectionResponse,
} = require('./mediaCollection');

describe('mediaCollection', () => {
  test('extracts carousel with video and image items', () => {
    const html =
      '"carousel_media":[' +
      '{"is_video":true,"video_versions":[{"url":"https://cdn.example.com/v1.mp4","width":720,"height":1280}],"thumbnail_url":"https://cdn.example.com/t1.jpg"},' +
      '{"is_video":false,"image_versions2":{"candidates":[{"url":"https://cdn.example.com/p1.jpg","width":1080,"height":1080}]}}' +
      ']';
    const items = extractCarouselFromHtml(html, 'ABC');
    expect(items.length).toBe(2);
    expect(items[0].mediaType).toBe('video');
    expect(items[1].mediaType).toBe('image');
    expect(items[0].mediaUrl).toBe('https://cdn.example.com/v1.mp4');
    expect(items[1].mediaUrl).toBe('https://cdn.example.com/p1.jpg');
  });

  test('buildCollectionResponse includes legacy videoUrl', () => {
    const items = [
      {
        id: 'x_0',
        index: 0,
        mediaType: 'video',
        mediaUrl: 'https://cdn.example.com/a.mp4',
        thumbnailUrl: 'https://cdn.example.com/t.jpg',
        duration: 10,
        fileName: 'quicksave_x_1.mp4',
        width: 720,
        height: 1280,
      },
    ];
    const r = buildCollectionResponse('carousel', items, { author: 'Alice' });
    expect(r.ok).toBe(true);
    expect(r.type).toBe('carousel');
    expect(r.itemCount).toBe(1);
    expect(r.videoUrl).toBe('https://cdn.example.com/a.mp4');
    expect(r.author).toBe('Alice');
  });

  test('extractStoriesFromHtml finds items array', () => {
    const html =
      '"items":[' +
      '{"video_versions":[{"url":"https://cdn.example.com/s1.mp4","width":720}],"thumbnail_url":"https://cdn.example.com/st1.jpg"},' +
      '{"video_versions":[{"url":"https://cdn.example.com/s2.mp4","width":720}],"thumbnail_url":"https://cdn.example.com/st2.jpg"}' +
      ']';
    const items = extractStoriesFromHtml(html, 'STORY1');
    expect(items.length).toBe(2);
    expect(items[0].mediaUrl).toContain('s1.mp4');
  });
});
