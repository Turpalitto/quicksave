const request = require('supertest');

process.env.NODE_ENV = 'test';
process.env.METRICS_PUBLIC = 'true';
const app = require('./index');

describe('Remote config endpoint', () => {
  test('GET /remote-config returns public client config', async () => {
    const res = await request(app).get('/remote-config');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.service).toBe('quicksave-backend');
    expect(res.body.version).toBeDefined();
    expect(res.body.config).toBeDefined();
    expect(Array.isArray(res.body.config.flags) === false).toBe(true);
    expect(typeof res.body.config.rateLimit.windowMs).toBe('number');
    expect(typeof res.body.config.rateLimit.max).toBe('number');
    expect(typeof res.body.config.cacheTtlMs).toBe('number');
  });

  test('GET /remote-config advertises no-store style freshness header', async () => {
    const res = await request(app).get('/remote-config');
    expect(res.headers['cache-control']).toContain('max-age=300');
  });
});

describe('Health stats endpoint', () => {
  test('GET /health/stats returns strategy and cache overview', async () => {
    const res = await request(app).get('/health/stats');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.service).toBe('quicksave-backend');
    expect(typeof res.body.cache.size).toBe('number');
    expect(res.body.stats).toBeDefined();
    expect(typeof res.body.stats.successRate).toBe('number');
    expect(typeof res.body.stats.cacheHitRate).toBe('number');
    expect(typeof res.body.stats.staleServed).toBe('number');
    expect(res.body.stats.strategies).toEqual({});
    expect(res.headers['cache-control']).toContain('no-store');
  });
});
