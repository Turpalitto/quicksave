const request = require('supertest');
const express = require('express');
const resolveRouter = require('./resolve');

describe('POST /resolve', () => {
  let app;

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/resolve', resolveRouter);
  });

  test('400 on empty body', async () => {
    const res = await request(app).post('/resolve').send({});
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ ok: false, error: 'invalid_url' });
  });

  test('400 on non-string url', async () => {
    const res = await request(app).post('/resolve').send({ url: 123 });
    expect(res.status).toBe(400);
    expect(res.body.ok).toBe(false);
  });

  test('400 on too long url', async () => {
    const longUrl = 'https://www.instagram.com/p/' + 'a'.repeat(2100);
    const res = await request(app).post('/resolve').send({ url: longUrl });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('invalid_url');
  });

  test('400 on non-instagram URL', async () => {
    const res = await request(app)
      .post('/resolve')
      .send({ url: 'https://example.com/' });
    expect(res.status).toBe(400);
    expect(res.body.ok).toBe(false);
  });

  test('400 on instagram explore path', async () => {
    const res = await request(app)
      .post('/resolve')
      .send({ url: 'https://www.instagram.com/explore' });
    expect(res.status).toBe(400);
  });

  test('400 on instagram stories URL', async () => {
    const res = await request(app)
      .post('/resolve')
      .send({ url: 'https://www.instagram.com/stories/abc/' });
    expect(res.status).toBe(400);
  });
});
