const { hashUrl, sanitizeUrlForLog } = require('./urlSanitizer');

describe('urlSanitizer', () => {
  test('hashUrl returns stable short hash', () => {
    const a = hashUrl('https://www.instagram.com/p/ABC123/');
    const b = hashUrl('https://www.instagram.com/p/ABC123/');
    expect(a).toBe(b);
    expect(a.length).toBe(12);
  });

  test('sanitizeUrlForLog redacts query and truncates path', () => {
    const s = sanitizeUrlForLog(
      'https://www.instagram.com/reel/ABC123/?utm_source=share',
    );
    expect(s).toContain('instagram.com');
    expect(s).not.toContain('utm_source');
  });
});
