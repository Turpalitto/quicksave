/**
 * Golden expected outcomes for resolver scenarios (structure assertions).
 */
module.exports = {
  reel: {
    url: 'https://www.instagram.com/reel/GOLDEN1/',
    expectOk: true,
    expectType: 'single',
    expectMediaType: 'video',
  },
  carousel: {
    url: 'https://www.instagram.com/p/CAROUSEL1/',
    expectOk: true,
    expectType: 'carousel',
    minItems: 2,
  },
  story: {
    url: 'https://www.instagram.com/stories/user/1234567890/',
    expectOk: true,
    expectType: 'story',
  },
  highlight: {
    url: 'https://www.instagram.com/stories/highlights/987654321/',
    expectOk: true,
    expectType: 'highlight',
  },
  profile: {
    url: 'https://www.instagram.com/natgeo/',
    expectOk: true,
    expectType: 'profile',
  },
  invalid: {
    url: 'https://example.com/not-instagram',
    expectOk: false,
    expectError: 'invalid_url',
  },
  private: {
    expectOk: false,
    expectError: 'private',
  },
  not_found: {
    expectOk: false,
    expectError: 'not_found',
  },
};
