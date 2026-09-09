describe('resolveCache stale lookups (SWR)', () => {
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  test('ResolveCache.getStale returns expired value and keeps it', async () => {
    const { ResolveCache } = require('./resolveCache');
    const cache = new ResolveCache(10, 5);
    const url = 'https://www.instagram.com/reel/stale1/';
    cache.set(url, { ok: true, items: [1] });
    expect(cache.get(url)).toEqual({ ok: true, items: [1] });
    await sleep(20);
    // Fresh get: expired → deleted → null
    expect(cache.get(url)).toBeNull();
    // Re-set, expire again, then stale lookup twice without eviction
    cache.set(url, { ok: true, items: [2] });
    await sleep(20);
    expect(cache.getStale(url)).toEqual({ ok: true, items: [2] });
    expect(cache.getStale(url)).toEqual({ ok: true, items: [2] });
  });

  test('ResolveCache.getStale returns null for unknown url', () => {
    const { ResolveCache } = require('./resolveCache');
    const cache = new ResolveCache(10, 600000);
    expect(cache.getStale('https://instagram.com/reel/none/')).toBeNull();
  });

  test('CompositeResolveCache.getStale returns memory value even when expired', async () => {
    const { CompositeResolveCache } = require('./resolveCache');
    const cache = new CompositeResolveCache();
    cache.memory.ttlMs = 5;
    const url = 'https://www.instagram.com/reel/stale2/';
    cache.set(url, { ok: true, items: [] });
    await sleep(20);
    // Stale lookup first: a fresh get() would delete the expired entry.
    expect(await cache.getStale(url)).toEqual({ ok: true, items: [] });
    expect(await cache.get(url)).toBeNull();
    expect(await cache.getStale(url)).toBeNull();
  });
});
