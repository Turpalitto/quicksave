const { CompositeResolveCache } = require('./resolveCache');

describe('CompositeResolveCache', () => {
  test('falls back to Redis when memory misses', async () => {
    const cache = new CompositeResolveCache();
    const payload = { ok: true, videoUrl: 'https://cdn.example.com/x.mp4' };
    const store = new Map();

    cache.attachRedis({
      isReady: true,
      get: jest.fn(async (key) => store.get(key) ?? null),
      setEx: jest.fn(async (key, _ttl, value) => {
        store.set(key, value);
      }),
    });

    store.set('resolve:https://instagram.com/reel/xyz', JSON.stringify(payload));

    await expect(cache.get('https://instagram.com/reel/xyz')).resolves.toEqual(payload);
    await expect(cache.get('https://instagram.com/reel/xyz')).resolves.toEqual(payload);
  });

  test('writes successful responses to Redis', async () => {
    const cache = new CompositeResolveCache();
    const setEx = jest.fn(async () => {});
    cache.attachRedis({
      isReady: true,
      get: jest.fn(async () => null),
      setEx,
    });

    const payload = { ok: true, id: 1 };
    cache.set('https://instagram.com/reel/abc', payload);

    expect(setEx).toHaveBeenCalledWith(
      'resolve:https://instagram.com/reel/abc',
      expect.any(Number),
      JSON.stringify(payload),
    );
  });

  test('skips Redis write for failed responses', () => {
    const cache = new CompositeResolveCache();
    const setEx = jest.fn(async () => {});
    cache.attachRedis({ isReady: true, get: jest.fn(), setEx });

    cache.set('https://instagram.com/reel/fail', { ok: false, error: 'private' });
    expect(setEx).not.toHaveBeenCalled();
    expect(cache.memory.get('https://instagram.com/reel/fail')).toBeNull();
  });
});
