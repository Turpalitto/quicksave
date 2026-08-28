jest.mock('axios');
const axios = require('axios');
const config = require('../config');

describe('fallbackProvider', () => {
  const saved = {
    url: config.fallbackApiUrl,
    key: config.fallbackApiKey,
    timeout: config.fallbackApiTimeoutMs,
  };

  beforeEach(() => {
    if (axios.post && axios.post.mockReset) axios.post.mockReset();
    config.fallbackApiUrl = 'https://api.example.com/resolve';
    config.fallbackApiKey = 'test-key';
    config.fallbackApiTimeoutMs = 15000;
  });

  afterAll(() => {
    config.fallbackApiUrl = saved.url;
    config.fallbackApiKey = saved.key;
    config.fallbackApiTimeoutMs = saved.timeout;
  });

  function load() {
    return require('./fallbackProvider');
  }

  test('disabled when env unset', async () => {
    config.fallbackApiUrl = '';
    config.fallbackApiKey = '';
    const { isFallbackConfigured, fetchFallbackMedia } = load();
    expect(isFallbackConfigured()).toBe(false);
    await expect(fetchFallbackMedia('https://instagram.com/reel/x/')).resolves.toBeNull();
    expect(axios.post).not.toHaveBeenCalled();
  });

  test('returns media on 2xx with mediaUrl', async () => {
    axios.post.mockResolvedValueOnce({
      status: 200,
      data: { mediaUrl: 'https://cdn.example/v.mp4', thumbnailUrl: 'https://cdn.example/t.jpg' },
    });
    const { isFallbackConfigured, fetchFallbackMedia } = load();
    expect(isFallbackConfigured()).toBe(true);
    const result = await fetchFallbackMedia('https://www.instagram.com/reel/abc/');
    expect(result).toEqual({
      ok: true,
      videoUrl: 'https://cdn.example/v.mp4',
      thumbnailUrl: 'https://cdn.example/t.jpg',
      via: 'fallback_api',
    });
    expect(axios.post).toHaveBeenCalledWith(
      'https://api.example.com/resolve',
      { url: 'https://www.instagram.com/reel/abc/' },
      expect.objectContaining({
        headers: expect.objectContaining({ Authorization: 'Bearer test-key' }),
      }),
    );
  });

  test('accepts videoUrl as alias for mediaUrl', async () => {
    axios.post.mockResolvedValueOnce({
      status: 200,
      data: { videoUrl: 'https://cdn.example/v2.mp4' },
    });
    const { fetchFallbackMedia } = load();
    const result = await fetchFallbackMedia('u');
    expect(result.ok).toBe(true);
    expect(result.videoUrl).toBe('https://cdn.example/v2.mp4');
    expect(result.thumbnailUrl).toBeNull();
  });

  test('null on non-2xx', async () => {
    axios.post.mockResolvedValueOnce({ status: 503, data: { mediaUrl: 'x' } });
    const { fetchFallbackMedia } = load();
    await expect(fetchFallbackMedia('u')).resolves.toBeNull();
  });

  test('null when payload has no media url', async () => {
    axios.post.mockResolvedValueOnce({ status: 200, data: { error: 'nope' } });
    const { fetchFallbackMedia } = load();
    await expect(fetchFallbackMedia('u')).resolves.toBeNull();
  });

  test('null when request throws (never throws)', async () => {
    axios.post.mockRejectedValueOnce(new Error('ECONNRESET'));
    const { fetchFallbackMedia } = load();
    await expect(fetchFallbackMedia('u')).resolves.toBeNull();
  });
});
