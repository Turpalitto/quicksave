const axios = require('axios');
const {
  resolveInstagramUrl,
  isValidPublicUrl,
  normalizeUrl,
  extractShortcode,
  buildEmbedUrl,
  extractVideoFromHtml,
  extractBestFromVideoVersions,
  isLoginWall,
} = require('./instagramResolver');

jest.mock('axios');

/**
 * Хелпер: успешный axios-ответ (HTTP 200).
 */
function htmlResponse(html) {
  return { data: html, status: 200 };
}

/**
 * Хелпер: ошибка axios с HTTP-статусом.
 */
function httpError(status) {
  const e = new Error(`HTTP ${status}`);
  e.response = { status };
  return e;
}

/**
 * Хелпер: ошибка сети (нет ответа).
 */
function networkError(code = 'ECONNABORTED') {
  const e = new Error('network');
  e.code = code;
  return e;
}

beforeEach(() => {
  axios.get.mockReset();
});

describe('isValidPublicUrl', () => {
  test.each([
    ['https://www.instagram.com/reel/ABC123/', true],
    ['https://instagram.com/reel/ABC123/', true],
    ['https://www.instagram.com/p/POST1/', true],
    ['https://www.instagram.com/tv/VID1/', true],
    ['https://instagr.am/reel/ABC123/', true],
    ['https://instagr.am/p/POST1/', true],
    ['https://www.instagram.com/explore', false],
    ['https://www.instagram.com/natgeo', true],
    ['https://www.instagram.com/stories/', false],
    ['https://example.com/', false],
    ['https://www.instagram.com/reel/ABC123/extra', false],
    ['not-a-url', false],
    ['https://example.com/?x=instagram.com/reel/abc', false],
  ])('isValidPublicUrl(%j) === %j', (url, expected) => {
    expect(isValidPublicUrl(url)).toBe(expected);
  });
});

describe('normalizeUrl', () => {
  test('adds https if missing', () => {
    expect(normalizeUrl('instagram.com/reel/X/')).toBe('https://instagram.com/reel/X');
  });
  test('keeps existing https', () => {
    expect(normalizeUrl('https://instagram.com/p/X/')).toBe('https://instagram.com/p/X');
  });
  test('removes trailing slash', () => {
    expect(normalizeUrl('https://instagram.com/p/X/')).toBe('https://instagram.com/p/X');
  });
  test('strips query and fragment', () => {
    expect(normalizeUrl('https://instagram.com/reel/X/?igsh=abc#frag')).toBe(
      'https://instagram.com/reel/X',
    );
  });
  test('normalizes /video/reel/ alias', () => {
    expect(normalizeUrl('https://www.instagram.com/video/reel/DWze_eKkrwr/')).toBe(
      'https://www.instagram.com/reel/DWze_eKkrwr',
    );
  });
  test('normalizes /reels/ alias', () => {
    expect(normalizeUrl('https://instagram.com/reels/ABC/')).toBe('https://instagram.com/reel/ABC');
  });
  test('fixes instagr.com typo to instagram.com', () => {
    expect(normalizeUrl('https://instagr.com/reel/ABC/')).toBe('https://instagram.com/reel/ABC');
  });
});

describe('extractShortcode / buildEmbedUrl', () => {
  test('extracts shortcode from canonical url', () => {
    expect(extractShortcode('https://instagram.com/reel/ABC123')).toBe('ABC123');
  });
  test('builds embed url', () => {
    expect(buildEmbedUrl('https://instagram.com/reel/ABC123')).toBe(
      'https://www.instagram.com/reel/ABC123/embed/captioned/',
    );
  });
});

describe('isLoginWall', () => {
  test('detects accounts/login marker', () => {
    expect(isLoginWall('<html>accounts/login</html>')).toBe(true);
  });
  test('detects "Login required"', () => {
    expect(isLoginWall('<html>"Login required"</html>')).toBe(true);
  });
  test('returns false for normal public html', () => {
    expect(isLoginWall('<html>og:video here</html>')).toBe(false);
  });
  test('returns false for empty', () => {
    expect(isLoginWall('')).toBe(false);
  });
});

describe('extractVideoFromHtml', () => {
  test('strategy 1: og:video:secure_url wins', () => {
    const html =
      '<meta property="og:video:secure_url" content="https://cdn.example.com/a.mp4">' +
      '<meta property="og:image" content="https://cdn.example.com/a.jpg">';
    const r = extractVideoFromHtml(html);
    expect(r.videoUrl).toBe('https://cdn.example.com/a.mp4');
    expect(r.thumbnailUrl).toBe('https://cdn.example.com/a.jpg');
  });

  test('strategy 1: og:video fallback', () => {
    const html = '<meta property="og:video" content="https://cdn.example.com/b.mp4">';
    expect(extractVideoFromHtml(html).videoUrl).toBe('https://cdn.example.com/b.mp4');
  });

  test('strategy 2: JSON-LD VideoObject contentUrl', () => {
    const html =
      '<script type="application/ld+json">' +
      '{"@type":"VideoObject","contentUrl":"https:\\/\\/cdn.example.com\\/c.mp4","thumbnailUrl":"https:\\/\\/cdn.example.com\\/c.jpg"}' +
      '</script>';
    const r = extractVideoFromHtml(html);
    expect(r.videoUrl).toBe('https://cdn.example.com/c.mp4');
    expect(r.thumbnailUrl).toBe('https://cdn.example.com/c.jpg');
  });

  test('strategy 3: embedded "video_url" with escaped slashes', () => {
    const html = '"video_url":"https:\\/\\/video-ams.cdninstagram.net\\/v.mp4?token=1"';
    expect(extractVideoFromHtml(html).videoUrl).toBe(
      'https://video-ams.cdninstagram.net/v.mp4?token=1',
    );
  });

  test('strategy 4: video_versions array picks best quality', () => {
    const html =
      '"video_versions":[' +
      '{"url":"https:\\/\\/cdn.example.com\\/low.mp4","width":480,"height":854},' +
      '{"url":"https:\\/\\/cdn.example.com\\/hd.mp4","width":1080,"height":1920}' +
      ']';
    expect(extractVideoFromHtml(html).videoUrl).toBe('https://cdn.example.com/hd.mp4');
  });

  test('strategy 5: playable_url', () => {
    const html = '"playable_url":"https:\\/\\/cdn.example.com\\/p.mp4"';
    expect(extractVideoFromHtml(html).videoUrl).toBe('https://cdn.example.com/p.mp4');
  });

  test('returns null when no video anywhere', () => {
    const html = '<html><body>just text, no video</body></html>';
    expect(extractVideoFromHtml(html)).toBeNull();
  });

  test('returns null for empty', () => {
    expect(extractVideoFromHtml('')).toBeNull();
  });
});

describe('resolveInstagramUrl', () => {
  test('returns invalid_url for /video/reel/ before normalization in validator', async () => {
    const r = await resolveInstagramUrl('https://example.com');
    expect(r).toEqual({ ok: false, error: 'invalid_url' });
  });

  test('accepts /video/reel/ alias after normalization', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) {
        return { data: { author_name: 'Alice' }, status: 200 };
      }
      if (url.includes('__a=1')) return { data: null, status: 200 };
      return htmlResponse(
        '<meta property="og:video:secure_url" content="https://cdn.example.com/reel.mp4">',
      );
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/video/reel/ABC/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://cdn.example.com/reel.mp4');
  });

  test('returns invalid_url for reserved profile path', async () => {
    const r = await resolveInstagramUrl('https://www.instagram.com/explore');
    expect(r).toEqual({ ok: false, error: 'invalid_url' });
  });

  test('resolves public profile URL', async () => {
    const html =
      '"edge_owner_to_timeline_media":{"edges":[' +
      '{"node":{"shortcode":"PROF1","is_video":true,"video_versions":[{"url":"https://cdn.example.com/p.mp4","width":720}]}}' +
      ']}';
    axios.get.mockImplementation(async (url) => {
      if (url.includes('web_profile_info')) return { data: { data: { user: null } }, status: 200 };
      if (url.includes('oembed')) return { data: {}, status: 200 };
      return htmlResponse(`<html>${html}</html>`);
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/natgeo');
    expect(r.ok).toBe(true);
    expect(r.type).toBe('profile');
    expect(r.items.length).toBeGreaterThan(0);
  });

  test('success via og:video on first UA', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: {}, status: 200 };
      if (url.includes('__a=1')) return { data: null, status: 200 };
      return htmlResponse(
        '<meta property="og:video:secure_url" content="https://cdn.example.com/reel.mp4">' +
          '<meta property="og:image" content="https://cdn.example.com/thumb.jpg">' +
          '<meta property="og:title" content="Alice • Instagram">',
      );
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/ABC/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://cdn.example.com/reel.mp4');
    expect(r.thumbnailUrl).toBe('https://cdn.example.com/thumb.jpg');
    expect(r.author).toBe('Alice');
    expect(r.fileName).toBe('quicksave_ABC.mp4');
  });

  test('success via embedded video_url when og:video absent', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: {}, status: 200 };
      if (url.includes('__a=1')) return { data: null, status: 200 };
      return htmlResponse(
        '<html><body>"video_url":"https:\\/\\/cdn.example.com\\/v.mp4"</body></html>',
      );
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/p/POST1/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://cdn.example.com/v.mp4');
  });

  test('success via GraphQL fallback when HTML has no video and no login wall', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: {}, status: 200 };
      if (url.includes('__a=1')) {
        return {
          data: {
            items: [{ video_versions: [{ url: 'https://cdn.example.com/gql.mp4', width: 720 }] }],
          },
          status: 200,
        };
      }
      return htmlResponse('<html>no video here, just text</html>');
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/X1/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://cdn.example.com/gql.mp4');
  });

  test('returns not_found on 404', async () => {
    axios.get.mockRejectedValue(httpError(404));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/NOPE/');
    expect(r).toEqual({ ok: false, error: 'not_found' });
  });

  test('returns private when login wall and GraphQL 404', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('__a=1')) {
        const e = new Error('HTTP 404');
        e.response = { status: 404 };
        throw e;
      }
      return htmlResponse('<html>accounts/login form here</html>');
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/PRIV/');
    expect(r).toEqual({ ok: false, error: 'private' });
  });

  test('returns private when all UAs hit login wall and GraphQL empty', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: {}, status: 200 };
      if (url.includes('__a=1')) {
        return { data: null, status: 200 };
      }
      return htmlResponse('<html>accounts/login form here</html>');
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/PRIV/');
    expect(r).toEqual({ ok: false, error: 'private' });
  });

  test('returns private on 401 from all UAs', async () => {
    axios.get.mockRejectedValue(httpError(401));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/PRIV2/');
    expect(r).toEqual({ ok: false, error: 'private' });
  });

  test('returns resolver_failed on persistent 4xx without login wall', async () => {
    axios.get.mockRejectedValue(httpError(400));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/WEIRD/');
    expect(r).toEqual({ ok: false, error: 'resolver_failed' });
  });

  test('returns resolver_failed on network error (no response)', async () => {
    axios.get.mockRejectedValue(networkError('ECONNABORTED'));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/TIMEOUT/');
    expect(r).toEqual({ ok: false, error: 'resolver_failed' });
  });

  test('embed page succeeds when main page has no video', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: {}, status: 200 };
      if (url.includes('__a=1')) return { data: null, status: 200 };
      if (url.includes('/embed/')) {
        return htmlResponse(
          '<meta property="og:video" content="https://cdn.example.com/embed.mp4">',
        );
      }
      return htmlResponse('<html>empty shell without video</html>');
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/EMBED1/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://cdn.example.com/embed.mp4');
  });

  test('resolves image-only single post via og:image', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) {
        return { data: { author_name: 'photo_user' }, status: 200 };
      }
      if (url.includes('__a=1')) return { data: null, status: 200 };
      return htmlResponse(
        '<meta property="og:image" content="https://cdn.example.com/photo.jpg">' +
          '<meta property="og:title" content="User on Instagram">',
      );
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/p/PHOTO1/');
    expect(r.ok).toBe(true);
    expect(r.items[0].mediaType).toBe('image');
    expect(r.items[0].mediaUrl).toContain('photo.jpg');
  });
});
