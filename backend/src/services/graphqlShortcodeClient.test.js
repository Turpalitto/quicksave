const { extractLsdToken } = require('./graphqlShortcodeClient');

describe('graphqlShortcodeClient', () => {
  test('extractLsdToken parses LSD token from bootstrap JSON', () => {
    const html = '{"LSD",[],{"token":"abc123xyz"}}';
    expect(extractLsdToken(html)).toBe('abc123xyz');
  });

  test('extractLsdToken parses alternate lsd field', () => {
    expect(extractLsdToken('prefix "lsd":"tok99" suffix')).toBe('tok99');
  });
});
