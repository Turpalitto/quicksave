# QuickSave

Privacy-first archiver for **public** Instagram media: Android app, Web PWA, Chrome extension. Share Intent, profiles, carousels, stories, Gallery, batch download.

> QuickSave works **only with public content** the user shared or pasted manually. No login, no anti-bot bypass.

> **Android:** API 30+ (Android 11), target API 36.

---

## Features

| Category | Features |
| --- | --- |
| Input | Share Intent, Quick Settings tile, clipboard, @username / URL |
| Content | Posts, Reels, carousels, stories, highlights, profiles + pagination |
| Download | Progress, HTTP Range resume, foreground service, notifications |
| Storage | App folder + optional Gallery (MediaStore) |
| UX | Material 3, RU/EN, onboarding, home widget |
| Pro | Play billing, watchlist, filename templates, cloud backup (WebDAV/S3), ZIP export |
| Web | PWA dashboard — resolve, library metadata, backend settings |
| Extension | Chrome MV3 — save from instagram.com → Web `?url=` flow |
| Backend | Hosted zero-config or self-hosted; Redis cache, metrics |

---

## Quick start

### Backend (local)

```bash
cd backend
npm install
npm start    # http://localhost:3000
npm test     # 115 tests
```

Production: [`backend/render.yaml`](backend/render.yaml), smoke check `npm run smoke:deploy`.

### Flutter

```bash
flutter pub get
flutter run
flutter test      # 141 tests
flutter analyze
```

### Extension

```bash
cd extension && npm test   # 6 tests
```

### Release AAB (Google Play)

1. Keystore: [`android/key.properties.example`](android/key.properties.example)
2. `flutter build appbundle --release`

---

## Backend URL

| Mode | Where |
| --- | --- |
| **Hosted** (default) | `AppConstants.hostedBackendUrl` → `https://quicksave-api.onrender.com` |
| **Self-hosted** (Pro) | Settings → Backend → Self-hosted |

| Environment | URL |
| --- | --- |
| Emulator | `http://10.0.2.2:3000` |
| LAN | `http://<IP>:3000` |

Free-tier hosted backends may cold-start ~30–60 s; the app retries health checks automatically.

---

## Project layout

```
quicksave/
├── lib/                    # Flutter app + Web PWA
├── android/                # Kotlin: Gallery, Widget, QS tile, FG service
├── backend/                # Express resolver + Docker + staged Web PWA
├── extension/              # Chrome MV3 extension
├── store/                  # Play listing, billing, release checklist
├── scripts/                # stage-web-for-backend.mjs, smoke-deploy.mjs
└── .github/workflows/      # CI (Flutter, Backend, Extension)
```

---

## Testing

```bash
flutter test && flutter analyze
cd backend && npm test && npm run lint
cd extension && npm test
node scripts/smoke-deploy.mjs https://quicksave-api.onrender.com
```

| Suite | Count |
| --- | --- |
| Flutter | 141 |
| Backend | 115 |
| Extension | 6 |

---

## Docs

| File | Description |
| --- | --- |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Product roadmap |
| [backend/README.md](backend/README.md) | Resolver API |
| [store/RELEASE_CHECKLIST.md](store/RELEASE_CHECKLIST.md) | Play + Render checklist |
| [store/BILLING_PRODUCTS.md](store/BILLING_PRODUCTS.md) | Play subscription IDs |

---

## Usage

Download only content you have rights to. Respect copyright and Instagram Terms of Service.
