#!/usr/bin/env node
/**
 * Smoke-test a deployed QuickSave backend (+ optional Web PWA root).
 *
 * Usage:
 *   node scripts/smoke-deploy.mjs
 *   node scripts/smoke-deploy.mjs https://quicksave-api.onrender.com
 *
 * Retries suit Render free-tier cold starts (~30–60 s).
 */
const base = (process.argv[2] || 'https://quicksave-api.onrender.com').replace(
  /\/$/,
  '',
);
const maxAttempts = Number(process.env.SMOKE_ATTEMPTS || 4);
const attemptTimeoutMs = Number(process.env.SMOKE_TIMEOUT_MS || 90_000);

async function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), attemptTimeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function probeHealth() {
  const res = await fetchWithTimeout(`${base}/health`);
  const body = await res.json();
  if (res.status !== 200 || body?.ok !== true) {
    throw new Error(`unhealthy: HTTP ${res.status} ${JSON.stringify(body)}`);
  }
  return body;
}

async function probeWebRoot() {
  const res = await fetchWithTimeout(`${base}/`, { method: 'HEAD' });
  if (res.status >= 400) {
    throw new Error(`web root HTTP ${res.status}`);
  }
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

let lastError;
for (let attempt = 1; attempt <= maxAttempts; attempt++) {
  try {
    console.log(`[${attempt}/${maxAttempts}] GET ${base}/health …`);
    const health = await probeHealth();
    console.log(`  ok — version ${health.version ?? 'unknown'}`);

    console.log(`HEAD ${base}/ …`);
    await probeWebRoot();
    console.log('  web PWA root OK');
    console.log('Smoke deploy: PASS');
    process.exit(0);
  } catch (err) {
    lastError = err;
    const msg = err?.name === 'AbortError' ? 'timeout' : err.message;
    console.warn(`  attempt ${attempt} failed: ${msg}`);
    if (attempt < maxAttempts) {
      const delay = attempt * 5000;
      console.log(`  waiting ${delay / 1000}s (cold start?) …`);
      await sleep(delay);
    }
  }
}

console.error(`Smoke deploy: FAIL — ${lastError?.message ?? lastError}`);
process.exit(1);
