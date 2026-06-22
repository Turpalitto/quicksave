const axios = require('axios');
const {
  extractVideoFromHtml,
  extractMetaTags,
  extractImageFromHtml,
  findVideoUrlInJson,
} = require('../src/services/postExtractor');
const { buildEmbedUrl } = require('../src/services/urlNormalizer');

const url = process.argv[2] || 'https://www.instagram.com/reel/DDN4ZQYoL9A/';

async function fetchHtml(target) {
  const res = await axios.get(target, {
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
  return { status: res.status, html: typeof res.data === 'string' ? res.data : '' };
}

async function main() {
  console.log('=== PAGE ===');
  const page = await fetchHtml(url);
  console.log('status', page.status, 'len', page.html.length);
  console.log('video extract', extractVideoFromHtml(page.html));

  const embed = buildEmbedUrl(url);
  console.log('\n=== EMBED', embed, '===');
  const emb = await fetchHtml(embed);
  console.log('status', emb.status, 'len', emb.html.length);
  console.log('meta', extractMetaTags(emb.html));
  console.log('video extract', extractVideoFromHtml(emb.html));

  console.log('\n=== GQL ?__a=1 ===');
  try {
    const gql = await axios.get(`${url}?__a=1&__d=dis`, {
      timeout: 15000,
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Linux; Android 14) Chrome/122 Mobile Safari/537.36',
        Accept: 'application/json',
        'x-ig-app-id': '936619743392459',
        Referer: url,
      },
      validateStatus: () => true,
    });
    console.log('status', gql.status, 'type', typeof gql.data);
    if (typeof gql.data === 'object') {
      console.log('video in json', findVideoUrlInJson(gql.data)?.slice(0, 80));
    } else {
      console.log('body head', String(gql.data).slice(0, 200));
    }
  } catch (e) {
    console.log('gql err', e.message);
  }

  console.log('\n=== OEMBED ===');
  try {
    const o = await axios.get('https://api.instagram.com/oembed', {
      params: { url, omitscript: true },
      timeout: 10000,
      validateStatus: () => true,
    });
    console.log('status', o.status, o.data);
  } catch (e) {
    console.log('oembed err', e.message);
  }

  // Parse application/json script blocks (Comet SSR payloads).
  const scriptRe = /<script type="application\/json"[^>]*>([\s\S]*?)<\/script>/gi;
  let sm;
  let scriptCount = 0;
  while ((sm = scriptRe.exec(page.html)) !== null) {
    scriptCount++;
    try {
      const j = JSON.parse(sm[1]);
      const v = findVideoUrlInJson(j);
      if (v) {
        console.log('\nFOUND video in script block', scriptCount, v.slice(0, 120));
        break;
      }
    } catch (_) {}
  }
  console.log('\nscript json blocks scanned', scriptCount);

  // Generic cdninstagram URL scan (unescaped).
  const direct = page.html.match(/https:\/\/[^"'\s\\]+cdninstagram\.com[^"'\s\\]+\.mp4/g);
  console.log('direct mp4 urls', direct ? direct.length : 0);
  if (direct && direct[0]) console.log('direct sample', direct[0].slice(0, 120));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
