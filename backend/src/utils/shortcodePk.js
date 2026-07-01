/**
 * Instagram shortcode ↔ numeric media pk (yt-dlp / instaloader algorithm).
 * @see https://stackoverflow.com/questions/24437823/getting-instagram-post-url-from-media-id
 */

const ENCODING_CHARS =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

function shortcodeToPk(shortcode) {
  if (!shortcode || typeof shortcode !== 'string') return null;
  let code = shortcode;
  if (code.length > 28) code = code.slice(0, -28);

  let pk = 0n;
  for (const char of code) {
    const idx = ENCODING_CHARS.indexOf(char);
    if (idx < 0) return null;
    pk = pk * 64n + BigInt(idx);
  }
  return pk.toString();
}

module.exports = { shortcodeToPk, ENCODING_CHARS };
