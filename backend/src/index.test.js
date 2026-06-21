const request = require('supertest');

// Устанавливаем NODE_ENV=test ДО require app, чтобы отключить логирование.
process.env.NODE_ENV = 'test';
process.env.METRICS_PUBLIC = 'true';
const app = require('./index');

describe('Health endpoints', () => {
  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.service).toBe('quicksave-backend');
    expect(res.body.version).toBeDefined();
  });

  test('GET /health/live returns ok', async () => {
    const res = await request(app).get('/health/live');
    expect(res.status).toBe(200);
    expect(res.body.live).toBe(true);
  });

  test('GET /version returns service version', async () => {
    const res = await request(app).get('/version');
    expect(res.status).toBe(200);
    expect(res.body.version).toBeDefined();
  });

  test('GET /health/ready returns ok', async () => {
    const res = await request(app).get('/health/ready');
    expect(res.status).toBe(200);
    expect(res.body.ready).toBe(true);
    expect(res.body.redis).toBe('disabled');
  });

  test('GET /health/metrics returns metrics when METRICS_PUBLIC=true', async () => {
    const res = await request(app).get('/health/metrics');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.metrics).toBeDefined();
    expect(typeof res.body.metrics.successRate).toBe('number');
  });

  test('Unknown API route returns 404 with code', async () => {
    const res = await request(app).get('/api/unknown');
    expect(res.status).toBe(404);
    expect(res.body.ok).toBe(false);
    expect(res.body.code).toBe('NOT_FOUND');
  });

  test('Malformed JSON body returns 400 invalid_json (not 500)', async () => {
    const res = await request(app)
      .post('/resolve')
      .set('Content-Type', 'application/json')
      .send('{ this is not valid json');
    expect(res.status).toBe(400);
    expect(res.body.ok).toBe(false);
    expect(res.body.error).toBe('invalid_json');
    expect(res.body.code).toBe('INVALID_JSON');
  });

  test('Too large JSON body returns 413', async () => {
    // express.json limit = 64kb. Шлём >64kb валидного JSON.
    const huge = { url: 'x'.repeat(70000) };
    const res = await request(app).post('/resolve').send(huge);
    expect(res.status).toBe(413);
    expect(res.body.ok).toBe(false);
    expect(res.body.error).toBe('payload_too_large');
    expect(res.body.code).toBe('PAYLOAD_TOO_LARGE');
  });
});

describe('Metrics protection', () => {
  test('metrics disabled without token when METRICS_PUBLIC=false', async () => {
    jest.resetModules();
    process.env.NODE_ENV = 'test';
    process.env.METRICS_PUBLIC = 'false';
    delete process.env.METRICS_TOKEN;
    const protectedApp = require('./index');
    const res = await request(protectedApp).get('/health/metrics');
    expect(res.status).toBe(503);
    expect(res.body.code).toBe('METRICS_DISABLED');
  });
});
