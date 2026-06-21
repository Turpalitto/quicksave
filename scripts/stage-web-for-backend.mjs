#!/usr/bin/env node
/**
 * Copies `build/web` (repo root) into `backend/public/web` for Docker/Render deploy.
 * Run from repo root after: flutter build web --release
 */
import { cpSync, existsSync, mkdirSync, rmSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const src = path.join(root, 'build', 'web');
const dest = path.join(root, 'backend', 'public', 'web');

if (!existsSync(src)) {
  console.error('Missing build/web — run: flutter build web --release');
  process.exit(1);
}

if (existsSync(dest)) {
  rmSync(dest, { recursive: true, force: true });
}
mkdirSync(path.dirname(dest), { recursive: true });
cpSync(src, dest, { recursive: true });
console.log(`Staged web PWA → ${dest}`);
