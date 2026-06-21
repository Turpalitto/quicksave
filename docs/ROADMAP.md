# QuickSave Roadmap

Privacy-first public Instagram media archiver — not a grey downloader.

## Phase 1 — Foundation

- [x] Backend modular resolver + golden tests
- [x] Protected `/health/metrics` (METRICS_TOKEN / METRICS_PUBLIC)
- [x] ESLint + Prettier + CI lint
- [x] Dependabot pub path fix
- [x] Request IDs + error codes
- [x] Android release minify/shrink (ProGuard + R8)

## Phase 2 — Media Library v2

- [x] Extended filters (reels, carousels, errors, recent, uncollected)
- [x] Sort options
- [x] Dedupe by URL / shortcode / media id
- [x] Provenance metadata model
- [x] Missing file status
- [x] Bulk actions UI (export ZIP, copy URLs, delete)
- [x] Filename templates in Settings UI

## Phase 3 — Automation

- [x] Watchlist screen + scheduler frequency validation
- [x] WorkManager constraints (Wi‑Fi, charging)
- [ ] Headless download (intentionally deferred — user must open app)
- [x] Check-now manual profile sync

## Phase 4 — Pro

- [x] Entitlements abstraction (demo + future remote stub)
- [x] ZIP + JSON + CSV export with attribution
- [x] Cloud backup adapters (WebDAV + S3; Google Drive OAuth deferred)
- [x] Remote billing (Google Play + license keys via EntitlementRepository)

## Phase 5 — Growth

- [x] Web dashboard / PWA (resolve preview, library metadata import, backend config)
- [x] Browser extension (Chrome MV3 — explicit save only)
- [ ] iOS
- [ ] Library sync
- [ ] Team collections

## Will NOT build

- Private content download
- Instagram login / cookies
- Anti-bot bypass
- Anonymous stalking / hidden story viewing
- Mass scraping without explicit user action
- Aggressive background polling
- Watermark removal claims
- Copyright-unsafe repost automation
