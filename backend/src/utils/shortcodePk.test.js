const { shortcodeToPk } = require('./shortcodePk');

describe('shortcodePk', () => {
  test('converts known shortcode to numeric pk', () => {
    const pk = shortcodeToPk('DOvzTywjPGN');
    expect(pk).toBeTruthy();
    expect(/^\d+$/.test(pk)).toBe(true);
  });

  test('returns null for invalid characters', () => {
    expect(shortcodeToPk('bad!!!code')).toBeNull();
  });
});
