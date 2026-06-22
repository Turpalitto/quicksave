const axios = require('axios');
const {
  extractVideoFromHtml,
  extractMetaTags,
  extractImageFromHtml,
} = require('./src/services/postExtractor');

const url = process.argv[2] || 'https://www.instagram.com/reel/DDN4ZQYoL9A/';

async function main() {
  const res = await axios.get(url, {
    timeout: 20000,
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
      Accept:
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      Referer: 'https://www.instagram.com/',
    },
    validateStatus: () => true,
  });
  const html = typeof res.data === 'string' ? res.data : '';
  console.log('status', res.status, 'len', html.length);
  console.log('login wall', /LoginAndSignup|challenge_required/i.test(html));
  const meta = extractMetaTags(html);
  console.log('meta', meta);
  const video = extractVideoFromHtml(html);
  console.log('video extract', video);
  const image = extractImageFromHtml(html);
  console.log('image extract', image ? image.slice(0, 80) : null);
  console.log('has video_versions', html.includes('video_versions'));
  console.log('has og:video', html.includes('og:video'));
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
