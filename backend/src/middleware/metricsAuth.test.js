const request = require('supertest');

process.env.NODE_ENV = 'test';
process.env.METRICS_PUBLIC = 'true';

describe('Metrics auth middleware', () => {
  test('rejects unauthorized when token required', async () => {
    jest.resetModules();
    process.env.NODE_ENV = 'test';
    process.env.METRICS_PUBLIC = 'false';
    process.env.METRICS_TOKEN = 'secret-token';
    const protectedApp = require('../index');
    const res = await request(protectedApp).get('/health/metrics');
    expect(res.status).toBe(401);
    expect(res.body.code).toBe('METRICS_UNAUTHORIZED');
  });

  test('allows bearer token', async () => {
    jest.resetModules();
    process.env.NODE_ENV = 'test';
    process.env.METRICS_PUBLIC = 'false';
    process.env.METRICS_TOKEN = 'secret-token';
    const protectedApp = require('../index');
    const res = await request(protectedApp)
      .get('/health/metrics')
      .set('Authorization', 'Bearer secret-token');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
  });
});
