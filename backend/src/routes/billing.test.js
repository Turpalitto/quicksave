const request = require('supertest');

process.env.NODE_ENV = 'test';
process.env.METRICS_PUBLIC = 'true';

const billingRouter = require('../routes/billing');
const express = require('express');

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/billing', billingRouter);
  return app;
}

describe('Billing routes', () => {
  afterEach(() => {
    delete process.env.BILLING_PLAY_VERIFY;
    delete process.env.BILLING_DEV_ACCEPT;
  });

  test('POST /billing/play/verify rejects missing body', async () => {
    const app = createApp();
    const res = await request(app).post('/billing/play/verify').send({});
    expect(res.status).toBe(400);
    expect(res.body.valid).toBe(false);
  });

  test('POST /billing/play/verify returns 501 when not configured', async () => {
    const app = createApp();
    const res = await request(app)
      .post('/billing/play/verify')
      .send({
        productId: 'quicksave_pro_monthly',
        purchaseToken: 'token',
        packageName: 'com.quicksave.app',
      });
    expect(res.status).toBe(501);
    expect(res.body.code).toBe('BILLING_VERIFY_NOT_CONFIGURED');
  });

  test('POST /billing/play/verify accepts in dev when enabled', async () => {
    process.env.BILLING_PLAY_VERIFY = '1';
    process.env.BILLING_DEV_ACCEPT = '1';
    const app = createApp();
    const res = await request(app)
      .post('/billing/play/verify')
      .send({
        productId: 'quicksave_pro_monthly',
        purchaseToken: 'token',
        packageName: 'com.quicksave.app',
      });
    expect(res.status).toBe(200);
    expect(res.body.valid).toBe(true);
  });
});
