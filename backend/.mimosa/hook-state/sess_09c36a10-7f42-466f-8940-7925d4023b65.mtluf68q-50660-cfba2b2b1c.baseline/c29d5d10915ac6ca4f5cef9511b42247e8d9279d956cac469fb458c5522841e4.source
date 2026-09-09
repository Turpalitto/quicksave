const {
  parseSetCookieHeaders,
  applyWwwClaimFromResponse,
  createSessionState,
  cookieHeader,
} = require('./instagramSession');

describe('instagramSession', () => {
  test('createSessionState starts with empty jar when env unset', () => {
    const s = createSessionState();
    expect(s.jar).toEqual({});
    expect(s.wwwClaim).toBe('');
  });

  test('parseSetCookieHeaders merges cookies', () => {
    const jar = parseSetCookieHeaders(['csrftoken=abc; Path=/', 'mid=xyz; HttpOnly']);
    expect(jar.csrftoken).toBe('abc');
    expect(jar.mid).toBe('xyz');
  });

  test('applyWwwClaimFromResponse captures claim header', () => {
    const state = { wwwClaim: '' };
    applyWwwClaimFromResponse({ 'x-ig-set-www-claim': 'hmac.abc' }, state);
    expect(state.wwwClaim).toBe('hmac.abc');
  });

  test('cookieHeader serializes jar', () => {
    expect(cookieHeader({ a: '1', b: '2' })).toBe('a=1; b=2');
  });
});
