# QuickSave — release checklist v1.3.1

## Automated test baseline (CI)

| Suite | Command | Expected |
|-------|---------|----------|
| Flutter | `flutter test` | **137** passed |
| Backend | `cd backend && npm test` | **115** passed |
| Extension | `cd extension && npm test` | **6** passed |

---

## Backend + Web (Render)

- [x] Push `main` → Render Blueprint sync (`backend/render.yaml`) — `d7c3393` on GitHub
- [ ] Set secrets in Render dashboard: `METRICS_TOKEN` (or `METRICS_PUBLIC=true` for dev)
- [ ] Optional: Redis from blueprint (`REDIS_URL` auto-wired)
- [ ] After deploy: `GET https://<host>/health` → `{ ok: true }`
- [ ] Web PWA: open `https://<host>/` → QuickSave Web dashboard
- [ ] Resolve smoke: paste public reel URL in Web → preview loads

### Refresh Web PWA on server

Web is bundled in Docker as `backend/public/web/`. After UI changes:

```bash
flutter build web --release
node scripts/stage-web-for-backend.mjs
git add backend/public/web
git commit -m "chore: refresh staged web PWA"
git push
```

Render redeploys on push (if auto-deploy enabled).

---

## Android signing + AAB

- [ ] Generate keystore (once): see `android/key.properties.example`
- [ ] Copy → `android/key.properties` (never commit)
- [ ] `flutter build appbundle --release`
- [ ] Output: `build/app/outputs/bundle/release/app-release.aab`
- [ ] **Without keystore** AAB is debug-signed — for Play upload you **must** use release keystore

### Device QA

- [ ] Share Intent → preview → download → Gallery
- [ ] History bulk: ZIP export, copy URLs, delete
- [ ] Pro demo key `QS-PRO-DEMO1` → watchlist, templates, cloud backup settings
- [ ] Google Play billing (after products created): Subscribe + Restore
- [ ] Quick Settings tile + widget
- [ ] Offline / backend down → clear errors

---

## Google Play Console

- [ ] Listing: `store/listing_en.md`, `store/listing_ru.md`
- [ ] Privacy: `store/privacy_policy.md` + **HTTPS URL** in Console
- [ ] Screenshots + feature graphic 1024×500
- [ ] Content rating + Data safety (no account, URL-only network use)
- [ ] **Subscriptions:** see `store/BILLING_PRODUCTS.md`
  - `quicksave_pro_monthly`
  - `quicksave_pro_yearly`

---

## Browser extension (optional)

- [ ] `chrome://extensions` → Load unpacked → `extension/`
- [ ] Save reel → opens Web `?url=` flow

---

## CI / Git

- [ ] GitHub Actions green: Flutter, Backend, Extension workflows
- [ ] Dependabot PRs reviewed

---

## Known limitations v1.3.1

- **Headless scheduler download** — not implemented; watchlist uses manual check
- **Google Drive backup** — OAuth deferred
- **Library sync** — metadata import/export only (Web), no live sync
- **Play verify** — server stub; set `BILLING_PLAY_VERIFY=1` for production
- Render free tier cold start ~30–60 s
