import test from 'node:test';
import assert from 'node:assert/strict';
import {
  buildDashboardResolveUrl,
  isSaveableInstagramPage,
  normalizeInstagramUrl,
} from '../src/shared.js';

test('normalizeInstagramUrl accepts public post', () => {
  const url = normalizeInstagramUrl('https://www.instagram.com/p/ABC123/');
  assert.equal(url, 'https://www.instagram.com/p/ABC123/');
});

test('normalizeInstagramUrl accepts reel', () => {
  const url = normalizeInstagramUrl('https://instagram.com/reel/XYZ/?utm=1');
  assert.ok(url?.includes('/reel/XYZ'));
  assert.ok(!url?.includes('utm'));
});

test('normalizeInstagramUrl rejects non-instagram', () => {
  assert.equal(normalizeInstagramUrl('https://example.com/p/1'), null);
});

test('normalizeInstagramUrl rejects profile-only for extension save', () => {
  assert.equal(normalizeInstagramUrl('https://www.instagram.com/username'), null);
});

test('buildDashboardResolveUrl encodes url param', () => {
  const out = buildDashboardResolveUrl(
    'https://www.instagram.com/p/ABC/',
    'https://dash.test',
  );
  assert.match(out, /^https:\/\/dash\.test\/\?url=/);
  assert.ok(out.includes(encodeURIComponent('https://www.instagram.com/p/ABC/')));
});

test('isSaveableInstagramPage', () => {
  assert.equal(
    isSaveableInstagramPage('https://www.instagram.com/reel/abc/'),
    true,
  );
  assert.equal(isSaveableInstagramPage('https://google.com'), false);
});
