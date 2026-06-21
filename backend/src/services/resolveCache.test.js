const { ResolveCache } = require('./resolveCache');

describe('ResolveCache', () => {
  test('stores and retrieves successful responses', () => {
    const cache = new ResolveCache(10, 60_000);
    const payload = { ok: true, videoUrl: 'https://cdn.example.com/a.mp4' };
    cache.set('https://instagram.com/reel/ABC', payload);
    expect(cache.get('https://instagram.com/reel/ABC')).toEqual(payload);
  });

  test('ignores failed responses', () => {
    const cache = new ResolveCache(10, 60_000);
    cache.set('https://instagram.com/reel/FAIL', { ok: false, error: 'private' });
    expect(cache.get('https://instagram.com/reel/FAIL')).toBeNull();
  });

  test('evicts oldest when max entries exceeded', () => {
    const cache = new ResolveCache(2, 60_000);
    cache.set('https://a', { ok: true, id: 1 });
    cache.set('https://b', { ok: true, id: 2 });
    cache.set('https://c', { ok: true, id: 3 });
    expect(cache.get('https://a')).toBeNull();
    expect(cache.get('https://c')).toEqual({ ok: true, id: 3 });
  });
});
