import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.dirname(fileURLToPath(import.meta.url));
const manifestPath = path.join(root, '..', 'manifest.json');
const raw = readFileSync(manifestPath, 'utf8');
const manifest = JSON.parse(raw);

if (manifest.manifest_version !== 3) {
  throw new Error('manifest_version must be 3');
}
if (!manifest.background?.service_worker) {
  throw new Error('missing background service_worker');
}
if (!Array.isArray(manifest.content_scripts) || manifest.content_scripts.length === 0) {
  throw new Error('missing content_scripts');
}

console.log('extension manifest OK');
