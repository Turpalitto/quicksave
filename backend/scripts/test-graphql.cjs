const axios = require('axios');

async function main() {
  const jar = {};
  const client = axios.create({
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/122.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
    },
    validateStatus: () => true,
    timeout: 20000,
  });

  client.interceptors.response.use((r) => {
    const sc = r.headers['set-cookie'];
    if (sc) {
      for (const c of sc) {
        const [kv] = c.split(';');
        const eq = kv.indexOf('=');
        if (eq > 0) jar[kv.slice(0, eq)] = kv.slice(eq + 1);
      }
    }
    return r;
  });

  const shortcode = process.argv[2] || 'DDN4ZQYoL9A';
  const pageUrl = `https://www.instagram.com/reel/${shortcode}/`;
  const page = await client.get(pageUrl);
  const html = page.data;
  const csrf = jar.csrftoken;
  const lsd =
    html.match(/"LSD",\[\],\{"token":"([^"]+)"\}/)?.[1] ||
    html.match(/"lsd":"([^"]+)"/)?.[1] ||
    '';

  console.log('page', page.status, 'csrf', !!csrf, 'lsd', lsd ? 'yes' : 'no');

  const cookie = Object.entries(jar)
    .map(([k, v]) => `${k}=${v}`)
    .join('; ');

  const docIds = [
    '24368985919464652',
    '10015901848480474',
    '25981206651899035',
    '8845758582119849',
  ];

  for (const docId of docIds) {
    const variables = encodeURIComponent(JSON.stringify({ shortcode }));
    const body = `variables=${variables}&doc_id=${docId}&lsd=${encodeURIComponent(lsd)}`;
    const gql = await client.post('https://www.instagram.com/graphql/query', body, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-IG-App-ID': '936619743392459',
        'X-CSRFToken': csrf || '',
        'X-FB-LSD': lsd,
        'X-ASBD-ID': '129477',
        Referer: pageUrl,
        Cookie: cookie,
      },
    });
    const d = gql.data;
    let video = null;
    if (d && typeof d === 'object') {
      video =
        d.data?.xdt_shortcode_media?.video_url ||
        d.data?.xdt_api__v1__media__shortcode__web_info?.items?.[0]?.video_versions?.[0]
          ?.url ||
        null;
    }
    console.log(
      'doc',
      docId,
      'status',
      gql.status,
      'video',
      video ? video.slice(0, 80) : typeof d === 'string' ? d.slice(0, 60) : JSON.stringify(d).slice(0, 80),
    );
    if (video) break;
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
