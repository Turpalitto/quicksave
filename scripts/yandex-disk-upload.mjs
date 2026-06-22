#!/usr/bin/env node
/**
 * Upload QuickSave release artifacts to Yandex Disk.
 *
 * Get OAuth token: https://oauth.yandex.ru/authorize?response_type=token&client_id=<app_id>
 * Or create app at https://oauth.yandex.ru/client/new (Disk access).
 *
 * Usage:
 *   set YANDEX_DISK_OAUTH=y0_AgA...
 *   node scripts/yandex-disk-upload.mjs
 *   node scripts/yandex-disk-upload.mjs path/to/file.apk
 */
import { createReadStream, existsSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const token = process.env.YANDEX_DISK_OAUTH || process.env.YANDEX_DISK_TOKEN;
if (!token) {
  console.error(
    'Set YANDEX_DISK_OAUTH (OAuth token with cloud_api:disk.write scope).',
  );
  process.exit(1);
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const defaultFiles = [
  path.join(root, 'release', 'QuickSave-v1.3.1+8-release.apk'),
  path.join(root, 'release', 'QuickSave-v1.3.1+8-release.aab'),
];
const files = process.argv.slice(2).length
  ? process.argv.slice(2).map((f) => path.resolve(f))
  : defaultFiles.filter(existsSync);

if (files.length === 0) {
  console.error('No files to upload. Run from repo after release/ is populated.');
  process.exit(1);
}

const remoteDir = process.env.YANDEX_DISK_PATH || '/QuickSave';

async function api(url, options = {}) {
  const res = await fetch(url, {
    ...options,
    headers: {
      Authorization: `OAuth ${token}`,
      ...(options.headers || {}),
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status} ${url}: ${text}`);
  }
  return res.status === 204 ? null : res.json();
}

async function ensureDir(dirPath) {
  try {
    await api(
      `https://cloud-api.yandex.net/v1/disk/resources?path=${encodeURIComponent(dirPath)}`,
    );
  } catch {
    await api(
      `https://cloud-api.yandex.net/v1/disk/resources?path=${encodeURIComponent(dirPath)}`,
      { method: 'PUT' },
    );
  }
}

async function uploadFile(localPath) {
  const name = path.basename(localPath);
  const remotePath = `${remoteDir}/${name}`;
  const size = statSync(localPath).size;
  console.log(`Uploading ${name} (${(size / 1024 / 1024).toFixed(1)} MB) → ${remotePath}`);

  const meta = await api(
    `https://cloud-api.yandex.net/v1/disk/resources/upload?path=${encodeURIComponent(remotePath)}&overwrite=true`,
  );

  const putRes = await fetch(meta.href, {
    method: 'PUT',
    body: createReadStream(localPath),
    duplex: 'half',
    headers: { 'Content-Length': String(size) },
  });
  if (!putRes.ok) {
    throw new Error(`PUT failed: ${putRes.status}`);
  }

  const published = await api(
    `https://cloud-api.yandex.net/v1/disk/resources/publish?path=${encodeURIComponent(remotePath)}`,
    { method: 'PUT' },
  );
  const linkMeta = await api(published.href);
  console.log(`  OK — public: ${linkMeta.public_url || '(publish pending)'}`);
  return linkMeta.public_url;
}

await ensureDir(remoteDir);
const links = [];
for (const f of files) {
  links.push(await uploadFile(f));
}
console.log('\nDone.');
for (const l of links.filter(Boolean)) console.log(l);
