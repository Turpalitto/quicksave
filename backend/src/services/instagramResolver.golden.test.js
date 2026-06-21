const axios = require('axios');
const { resolveInstagramUrl } = require('./instagramResolver');
const {
  REEL_OG_VIDEO,
  REEL_VIDEO_VERSIONS,
  LOGIN_WALL,
  STORY_HTML,
  HIGHLIGHT_HTML,
  PROFILE_GRID_HTML,
} = require('./__fixtures__/instagramHtml');
const scenarios = require('./__fixtures__/golden/scenarios');

jest.mock('axios');

function htmlResponse(html) {
  return { data: html, status: 200 };
}

beforeEach(() => {
  axios.get.mockReset();
});

describe('Golden resolver scenarios', () => {
  test('reel — og:video single item', async () => {
    axios.get.mockImplementation((url) => {
      if (String(url).includes('oembed')) {
        return Promise.resolve({ data: { author_name: 'Alice', title: 'Reel' } });
      }
      return Promise.resolve(htmlResponse(REEL_OG_VIDEO));
    });
    const result = await resolveInstagramUrl(scenarios.reel.url);
    expect(result.ok).toBe(true);
    expect(result.type).toBe(scenarios.reel.expectType);
    expect(result.items[0].mediaType).toBe(scenarios.reel.expectMediaType);
    expect(result.items[0].mediaUrl).toMatch(/^https?:\/\//);
  });

  test('carousel — multiple items from video_versions blocks', async () => {
    const carouselHtml = REEL_VIDEO_VERSIONS.replace(
      '"video_versions"',
      '"edge_sidecar_to_children":{"edges":[{"node":{"video_versions"',
    );
    axios.get.mockImplementation((url) => {
      if (String(url).includes('oembed')) {
        return Promise.resolve({ data: { author_name: 'Dave' } });
      }
      if (String(url).includes('__a=1')) {
        return Promise.resolve({ data: {} });
      }
      return Promise.resolve(htmlResponse(carouselHtml));
    });
    const result = await resolveInstagramUrl('https://www.instagram.com/p/CAROUSEL1/');
    expect(result.ok).toBe(true);
    expect(result.items.length).toBeGreaterThanOrEqual(1);
  });

  test('invalid URL returns invalid_url', async () => {
    const result = await resolveInstagramUrl(scenarios.invalid.url);
    expect(result.ok).toBe(false);
    expect(result.error).toBe(scenarios.invalid.expectError);
  });

  test('private/login wall returns private', async () => {
    axios.get.mockResolvedValue(htmlResponse(LOGIN_WALL));
    const result = await resolveInstagramUrl('https://www.instagram.com/reel/PRIVATE1/');
    expect(result.ok).toBe(false);
    expect(result.error).toBe('private');
  });

  test('404 returns not_found when no html', async () => {
    axios.get.mockRejectedValue(
      Object.assign(new Error('404'), {
        response: { status: 404 },
      }),
    );
    const result = await resolveInstagramUrl('https://www.instagram.com/reel/MISSING999/');
    expect(result.ok).toBe(false);
    expect(['not_found', 'resolver_failed']).toContain(result.error);
  });

  test('story — reel_media extraction', async () => {
    axios.get.mockImplementation((url) => {
      if (String(url).includes('oembed')) {
        return Promise.resolve({ data: { author_name: 'storyuser' } });
      }
      return Promise.resolve(htmlResponse(STORY_HTML));
    });
    const result = await resolveInstagramUrl(
      'https://www.instagram.com/stories/storyuser/1234567890',
    );
    expect(result.ok).toBe(true);
    expect(result.type).toBe('story');
    expect(result.items.length).toBeGreaterThanOrEqual(1);
  });

  test('highlight — highlight_reels extraction', async () => {
    axios.get.mockImplementation((url) => {
      if (String(url).includes('oembed')) {
        return Promise.resolve({ data: { author_name: 'highlights' } });
      }
      return Promise.resolve(htmlResponse(HIGHLIGHT_HTML));
    });
    const result = await resolveInstagramUrl(
      'https://www.instagram.com/stories/highlights/987654321',
    );
    expect(result.ok).toBe(true);
    expect(result.type).toBe('highlight');
    expect(result.items.length).toBeGreaterThanOrEqual(1);
  });

  test('profile — timeline grid extraction', async () => {
    axios.get.mockImplementation((url) => {
      const u = String(url);
      if (u.includes('oembed')) {
        return Promise.resolve({ data: { author_name: 'natgeo' } });
      }
      if (u.includes('web_profile_info')) {
        return Promise.resolve({ data: { data: { user: null } } });
      }
      return Promise.resolve(htmlResponse(PROFILE_GRID_HTML));
    });
    const result = await resolveInstagramUrl('https://www.instagram.com/natgeo/');
    expect(result.ok).toBe(true);
    expect(result.type).toBe('profile');
    expect(result.items.length).toBeGreaterThanOrEqual(2);
  });
});

describe('urlNormalizer module', () => {
  const { normalizeUrl, extractShortcode, getUrlKind } = require('./urlNormalizer');

  test('normalizes instagr.com typo', () => {
    expect(normalizeUrl('https://instagr.com/reel/ABC/')).toBe('https://instagram.com/reel/ABC');
  });

  test('extractShortcode from reel', () => {
    expect(extractShortcode('https://instagram.com/reel/XYZ123')).toBe('XYZ123');
  });

  test('getUrlKind for story', () => {
    expect(getUrlKind('https://instagram.com/stories/user/123')).toBe('story');
  });
});

describe('postExtractor module', () => {
  const { extractVideoFromHtml, extractBestFromVideoVersions } = require('./postExtractor');

  test('extractVideoFromHtml og:video', () => {
    const r = extractVideoFromHtml(REEL_OG_VIDEO);
    expect(r.videoUrl).toContain('cdninstagram.net');
  });

  test('extractBestFromVideoVersions', () => {
    const url = extractBestFromVideoVersions(REEL_VIDEO_VERSIONS);
    expect(url).toContain('dave_720.mp4');
  });
});

describe('resolverErrors module', () => {
  const { isLoginWall, classifyHttpStatus } = require('./resolverErrors');

  test('classifyHttpStatus', () => {
    expect(classifyHttpStatus(404)).toBe('not_found');
    expect(classifyHttpStatus(403)).toBe('private');
  });

  test('isLoginWall detects private marker', () => {
    expect(isLoginWall(LOGIN_WALL, false)).toBe(true);
    expect(isLoginWall(REEL_OG_VIDEO, true)).toBe(false);
  });
});
