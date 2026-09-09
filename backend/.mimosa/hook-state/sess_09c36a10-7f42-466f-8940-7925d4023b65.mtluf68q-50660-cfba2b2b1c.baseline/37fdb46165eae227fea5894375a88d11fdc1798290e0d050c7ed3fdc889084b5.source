describe('instagramSession cookie pool', () => {
  const saved = process.env.INSTAGRAM_COOKIES_POOL;

  afterEach(() => {
    if (saved === undefined) delete process.env.INSTAGRAM_COOKIES_POOL;
    else process.env.INSTAGRAM_COOKIES_POOL = saved;
    jest.resetModules();
  });

  test('empty pool → null and single-jar mode', () => {
    process.env.INSTAGRAM_COOKIES_POOL = '';
    jest.resetModules();
    const { nextPooledCookieJar, createSessionState } = require('./instagramSession');
    expect(nextPooledCookieJar()).toBeNull();
    const s = createSessionState();
    expect(s.jar).toEqual({});
    expect(s.wwwClaim).toBe('');
  });

  test('rotates jars round-robin across JSON and header formats', () => {
    process.env.INSTAGRAM_COOKIES_POOL = '{"sessionid":"aaa"}||sessionid=bbb; csrftoken=cc';
    jest.resetModules();
    const mod = require('./instagramSession');
    mod.resetPoolCounter();
    expect(mod.createSessionState().jar).toEqual({ sessionid: 'aaa' });
    expect(mod.createSessionState().jar).toEqual({ sessionid: 'bbb', csrftoken: 'cc' });
    expect(mod.createSessionState().jar).toEqual({ sessionid: 'aaa' });
  });

  test('skips empty pool entries', () => {
    process.env.INSTAGRAM_COOKIES_POOL = '||{"sessionid":"only"}||';
    jest.resetModules();
    const mod = require('./instagramSession');
    mod.resetPoolCounter();
    expect(mod.createSessionState().jar).toEqual({ sessionid: 'only' });
    expect(mod.createSessionState().jar).toEqual({ sessionid: 'only' });
  });
});
