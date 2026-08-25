#!/usr/bin/env node
/**
 * Generates QuickSave Pro license keys compatible with lib/services/pro_service.dart.
 *
 * Usage:
 *   node scripts/generate-license-key.mjs            # personal key
 *   node scripts/generate-license-key.mjs --selfhost # self-hosted key
 *   node scripts/generate-license-key.mjs -n 5       # batch of keys
 */

const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

function checksumFor(payload) {
  const salted = payload.startsWith('SHOST')
    ? `selfhosted:${payload}`
    : `personal:${payload}`;
  let h = 5381;
  for (const ch of salted) {
    h = ((h * 33) + ch.codePointAt(0)) & 0x3fffffff;
  }
  return ALPHABET[(h >> 5) % ALPHABET.length] + ALPHABET[h % ALPHABET.length];
}

function randomBody(length) {
  let out = '';
  for (let i = 0; i < length; i++) {
    out += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  }
  return out;
}

function generateKey(selfHosted) {
  const payload = selfHosted
    ? `SHOST${randomBody(6)}`
    : randomBody(8);
  return `QS-PRO-${payload}-${checksumFor(payload)}`;
}

const args = process.argv.slice(2);
const selfHosted = args.includes('--selfhost');
const nIndex = args.indexOf('-n');
const count = nIndex >= 0 ? Math.max(1, parseInt(args[nIndex + 1] || '1', 10)) : 1;

for (let i = 0; i < count; i++) {
  console.log(generateKey(selfHosted));
}
