const {
  extractLsdToken,
  extractDocIdFromHtml,
  SHORTCODE_DOC_IDS,
  PRIMARY_DOC_ID,
} = require('./graphqlShortcodeClient');

describe('graphqlShortcodeClient', () => {
  test('extractLsdToken parses LSD token from bootstrap JSON', () => {
    const html = '{"LSD",[],{"token":"abc123xyz"}}';
    expect(extractLsdToken(html)).toBe('abc123xyz');
  });

  test('extractLsdToken parses alternate lsd field', () => {
    expect(extractLsdToken('prefix "lsd":"tok99" suffix')).toBe('tok99');
  });

  test('extractDocIdFromHtml finds doc_id in HTML', () => {
    const html = 'bootstrap "doc_id":"24368985919464652" end';
    expect(extractDocIdFromHtml(html)).toBe('24368985919464652');
  });

  test('extractDocIdFromHtml returns null when missing', () => {
    expect(extractDocIdFromHtml('<html></html>')).toBeNull();
  });

  test('PRIMARY_DOC_ID matches yt-dlp Relay query', () => {
    expect(PRIMARY_DOC_ID).toBe('8845758582119845');
  });

  test('SHORTCODE_DOC_IDS is a non-empty fallback list', () => {
    expect(Array.isArray(SHORTCODE_DOC_IDS)).toBe(true);
    expect(SHORTCODE_DOC_IDS.length).toBeGreaterThan(0);
  });
});
