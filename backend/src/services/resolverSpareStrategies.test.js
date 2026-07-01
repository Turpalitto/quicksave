jest.mock('./upstreamClient', () => ({
  fetchOembedMetadata: jest.fn().mockResolvedValue(null),
  fetchHtml: jest.fn(),
  USER_AGENTS: ['test-ua'],
}));

const { fetchOembedMetadata } = require('./upstreamClient');
const { tryVideoVersionsInHtml } = require('./resolverSpareStrategies');

describe('resolverSpareStrategies', () => {
  beforeEach(() => {
    fetchOembedMetadata.mockClear();
  });

  test('tryVideoVersionsInHtml extracts from video_versions JSON', async () => {
    const html =
      '"video_versions":[{"url":"https://cdn.example.com/spare.mp4","width":720,"height":1280}]';
    const result = await tryVideoVersionsInHtml(
      html,
      'ABC123',
      'https://www.instagram.com/reel/ABC123/',
      'post',
    );
    expect(result).toBeTruthy();
    expect(result.ok).toBe(true);
    expect(result.items[0].mediaUrl).toContain('spare.mp4');
    expect(fetchOembedMetadata).toHaveBeenCalledTimes(1);
  });
});
