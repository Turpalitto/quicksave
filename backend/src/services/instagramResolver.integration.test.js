/**
 * Интеграционные тесты резолвера с реалистичными HTML-фикстурами.
 *
 * Имитируют настоящие ответы Instagram и проверяют полный путь
 * resolveInstagramUrl: мок axios возвращает HTML/JSON-фикстуру,
 * резолвер должен извлечь корректный videoUrl через нужную стратегию.
 *
 * Это максимально близко к реальной работе без сетевых запросов.
 */
const axios = require('axios');
const { resolveInstagramUrl, extractVideoFromHtml } = require('./instagramResolver');
const F = require('./__fixtures__/instagramHtml');

jest.mock('axios');

function htmlOk(html) {
  return { data: html, status: 200 };
}
function jsonOk(obj) {
  return { data: obj, status: 200 };
}

beforeEach(() => {
  axios.get.mockReset();
});

describe('Integration: resolver extracts videoUrl from realistic HTML', () => {
  test('Reel with og:video:secure_url → direct CDN url', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: { author_name: 'Alice' }, status: 200 };
      if (url.includes('__a=1')) return jsonOk(null);
      return htmlOk(F.REEL_OG_VIDEO);
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Cabc123/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toContain('video-ams.cdninstagram.net');
    expect(r.videoUrl).toContain('.mp4');
    expect(r.thumbnailUrl).toContain('thumb.jpg');
    expect(r.author).toBe('Alice');
    expect(r.duration).toBe(14);
    expect(r.fileName).toBe('quicksave_Cabc123.mp4');
  });

  test('Post with JSON-LD VideoObject when og:video absent', async () => {
    axios.get.mockResolvedValue(htmlOk(F.POST_JSON_LD));
    const r = await resolveInstagramUrl('https://www.instagram.com/p/Def456/');
    expect(r.ok).toBe(true);
    // URL должен быть разэскейплен (\/ -> /)
    expect(r.videoUrl).toBe('https://video-fra.cdninstagram.net/v/t50.99/bob_vid.mp4?token=abc123');
    expect(r.thumbnailUrl).toBe('https://scontent.cdninstagram.net/v/bob/thumb.jpg');
    expect(r.fileName).toBe('quicksave_Def456.mp4');
  });

  test('Reel with embedded "video_url" in JS (escaped slashes)', async () => {
    axios.get.mockResolvedValue(htmlOk(F.REEL_EMBEDDED_VIDEO_URL));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Ghi789/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://video-sin.cdninstagram.net/v/carol.mp4?oe=111&efg=222');
    expect(r.thumbnailUrl).toBe('https://scontent.cdninstagram.net/carol_thumb.jpg');
  });

  test('Reel with video_versions[] array (mobile response)', async () => {
    axios.get.mockResolvedValue(htmlOk(F.REEL_VIDEO_VERSIONS));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Jkl012/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://video-lax.cdninstagram.net/v/dave_720.mp4');
  });

  test('GraphQL fallback when HTML has no video and no login wall', async () => {
    // HTML без видео → идём в GraphQL, который отдаёт JSON с video_versions.
    const noVideoHtml =
      '<!DOCTYPE html><html><head><meta property="og:title" content="x"></head>' +
      '<body>no video here</body></html>';
    axios.get.mockImplementation(async (url) => {
      if (url.includes('__a=1')) return jsonOk(JSON.parse(F.GRAPHQL_JSON));
      return htmlOk(noVideoHtml);
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Mno345/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://video-ams.cdninstagram.net/v/gql_fallback.mp4?token=zzz');
  });

  test('GraphQL fallback finds deeply nested video_url (shortcode_media)', async () => {
    const noVideoHtml = '<html><body>nothing</body></html>';
    axios.get.mockImplementation(async (url) => {
      if (url.includes('__a=1')) return jsonOk(JSON.parse(F.GRAPHQL_NESTED_JSON));
      return htmlOk(noVideoHtml);
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/p/Pqr678/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toBe('https://video-fra.cdninstagram.net/v/nested.mp4?sig=abc');
  });

  test('Login wall on all UAs → private (no GraphQL video)', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('__a=1')) return jsonOk(null); // GraphQL тоже пусто/блок
      return htmlOk(F.LOGIN_WALL);
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Priv1/');
    expect(r).toEqual({ ok: false, error: 'private' });
  });

  test('Empty HTML → not_found', async () => {
    axios.get.mockResolvedValue(htmlOk(F.EMPTY_HTML));
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Stu901/');
    expect(r).toEqual({ ok: false, error: 'not_found' });
  });

  test('first source login wall, embed returns og:video → success', async () => {
    axios.get.mockImplementation(async (url) => {
      if (url.includes('oembed')) return { data: {}, status: 200 };
      if (url.includes('__a=1')) return jsonOk(null);
      if (url.includes('/embed/')) return htmlOk(F.REEL_OG_VIDEO);
      return htmlOk(F.LOGIN_WALL);
    });
    const r = await resolveInstagramUrl('https://www.instagram.com/reel/Vwx234/');
    expect(r.ok).toBe(true);
    expect(r.videoUrl).toContain('video-ams.cdninstagram.net');
  });

  test('extractVideoFromHtml prefers og:video:secure_url over og:video', () => {
    const html =
      '<meta property="og:video" content="http://insecure.example.com/a.mp4">' +
      '<meta property="og:video:secure_url" content="https://cdn.example.com/a.mp4">';
    expect(extractVideoFromHtml(html).videoUrl).toBe('https://cdn.example.com/a.mp4');
  });

  test('all fixture extraction strategies are mutually exclusive and ordered', () => {
    // Если в HTML есть и og:video и video_versions — должна победить og:video (стратегия 1).
    const html =
      F.REEL_VIDEO_VERSIONS +
      '<meta property="og:video" content="https://cdn.example.com/og_wins.mp4">';
    expect(extractVideoFromHtml(html).videoUrl).toBe('https://cdn.example.com/og_wins.mp4');
  });
});

describe('Integration: URL normalization with real-world inputs', () => {
  test('reel URL with tracking query (?igsh=...) is stripped', async () => {
    axios.get.mockResolvedValue(htmlOk(F.REEL_OG_VIDEO));
    const input =
      'https://www.instagram.com/reel/Cabc123/?igshid=MWZjczhkZGY%3D&utm_source=ig_share';
    const r = await resolveInstagramUrl(input);
    expect(r.ok).toBe(true);
    // axios.get должен вызываться с нормализованным URL без query
    const calledUrl = axios.get.mock.calls[0][0];
    expect(calledUrl).not.toContain('igshid');
    expect(calledUrl).not.toContain('utm_source');
    expect(calledUrl).toBe('https://www.instagram.com/reel/Cabc123');
  });

  test('share text "Check this out https://instagram.com/reel/X/" is NOT auto-extracted (client job)', async () => {
    // Сервер ожидает уже извлечённый URL; полный текст — ошибка валидации.
    axios.get.mockResolvedValue(htmlOk(F.REEL_OG_VIDEO));
    const r = await resolveInstagramUrl('Check this out https://instagram.com/reel/X/');
    expect(r.ok).toBe(false);
    expect(r.error).toBe('invalid_url');
  });
});
