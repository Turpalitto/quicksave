/**
 * Реалистичные HTML-фикстуры, имитирующие ответы Instagram.
 *
 * Структуры основаны на реальной разметке публичных страниц Instagram:
 *   - og:мета в <head>
 *   - JSON-LD <script type="application/ld+json">
 *   - встроенный JS с экранированными URL ("video_url":"https:\/\/...")
 *   - массив "video_versions":[{"url":"..."}]
 *   - login wall для приватных/ограниченных постов
 *
 * Используются в интеграционных тестах резолвера, чтобы проверить
 * извлечение прямых ссылок в условиях, близких к настоящим.
 */

/** Публичный Reel с og:video:secure_url (классический случай). */
const REEL_OG_VIDEO = `<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
  <meta charset="utf-8">
  <title>Reel by Alice on Instagram</title>
  <meta property="og:title" content="Reel by Alice on Instagram">
  <meta property="og:type" content="video.other">
  <meta property="og:video:secure_url" content="https://video-ams.cdninstagram.net/v/t66.12345/12345678_abc/mp4/720.mp4?oe=65A1B2C3&efg=xyz">
  <meta property="og:video" content="https://video-ams.cdninstagram.net/v/t66.12345/12345678_abc/mp4/720.mp4?oe=65A1B2C3&efg=xyz">
  <meta property="og:image" content="https://scontent.cdninstagram.net/v/abc/thumb.jpg">
  <meta property="video:duration" content="14">
  <meta property="og:site_name" content="Instagram">
</head>
<body></body>
</html>`;

/** Публичный пост с JSON-LD VideoObject (нет og:video). */
const POST_JSON_LD = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Video by Bob on Instagram</title>
  <meta property="og:title" content="Bob on Instagram">
  <meta property="og:image" content="https://scontent.cdninstagram.net/v/bob/thumb.jpg">
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "VideoObject",
    "contentUrl": "https:\\/\\/video-fra.cdninstagram.net\\/v\\/t50.99\\/bob_vid.mp4?token=abc123",
    "thumbnailUrl": "https:\\/\\/scontent.cdninstagram.net\\/v\\/bob\\/thumb.jpg",
    "name": "Cool video",
    "duration": "PT22S"
  }
  </script>
</head>
<body></body>
</html>`;

/** Публичный пост без og:video и без JSON-LD, но со встроенным JS video_url. */
const REEL_EMBEDDED_VIDEO_URL = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta property="og:title" content="Carol on Instagram">
  <meta property="og:image" content="https://scontent.cdninstagram.net/carol.jpg">
</head>
<body>
  <script type="application/javascript">
    window.__additionalData = {"data":{"video_url":"https:\\/\\/video-sin.cdninstagram.net\\/v\\/carol.mp4?oe=111&efg=222","thumbnail_url":"https:\\/\\/scontent.cdninstagram.net\\/carol_thumb.jpg"}};
  </script>
</body>
</html>`;

/** Публичный пост с video_versions[] массивом (мобильный ответ). */
const REEL_VIDEO_VERSIONS = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta property="og:title" content="Dave on Instagram">
  <meta property="og:image" content="https://scontent.cdninstagram.net/dave.jpg">
</head>
<body>
  <script>
    var media = {"video_versions":[{"id":"1","type":101,"url":"https:\\/\\/video-lax.cdninstagram.net\\/v\\/dave_720.mp4","width":720,"height":1280}],"image_versions":[{"url":"https:\\/\\/scontent.cdninstagram.net\\/dave_thumb.jpg","width":480}]};
  </script>
</body>
</html>`;

/** Login wall — Instagram отдаёт HTML с формой входа вместо поста. */
const LOGIN_WALL = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Login • Instagram</title>
  <meta property="og:title" content="Login • Instagram">
</head>
<body>
  <div class="login-form">
    <form action="/accounts/login/" method="post">
      <input name="username"><input name="password" type="password">
    </form>
    <script>window.__additionalData = {"isLoggedIn":false};</script>
  </div>
</body>
</html>`;

/** Пустой HTML (нестандартный ответ). */
const EMPTY_HTML = '';

/** GraphQL JSON-ответ для fallback (имитация ?__a=1&__d=dis). */
const GRAPHQL_JSON = JSON.stringify({
  items: [
    {
      pk: '999',
      id: '999_123',
      video_versions: [
        { type: 101, url: 'https://video-ams.cdninstagram.net/v/gql_fallback.mp4?token=zzz' },
      ],
      image_versions: [
        { url: 'https://scontent.cdninstagram.net/gql_thumb.jpg' },
      ],
    },
  ],
});

/** GraphQL JSON, где URL глубоко вложен (имитация реальной структуры shortcode_media). */
const GRAPHQL_NESTED_JSON = JSON.stringify({
  data: {
    shortcode_media: {
      id: '123',
      shortcode: 'Cxyz123',
      video_url: 'https://video-fra.cdninstagram.net/v/nested.mp4?sig=abc',
      owner: { username: 'eve' },
    },
  },
  status: 'ok',
});

module.exports = {
  REEL_OG_VIDEO,
  POST_JSON_LD,
  REEL_EMBEDDED_VIDEO_URL,
  REEL_VIDEO_VERSIONS,
  LOGIN_WALL,
  EMPTY_HTML,
  GRAPHQL_JSON,
  GRAPHQL_NESTED_JSON,
};
