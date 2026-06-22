# QuickSave — release checklist v1.3.1

## Automated test baseline (CI)

| Suite | Command | Expected |
|-------|---------|----------|
| Flutter | `flutter test` | **141** passed |
| Backend | `cd backend && npm test` | **115** passed |
| Extension | `cd extension && npm test` | **6** passed |

---

## Backend + Web (Render)

Пошагово (≈10 мин):

1. **Dashboard:** [render.com/dashboard](https://dashboard.render.com) → **New** → **Blueprint** → подключить репо `Turpalitto/quicksave`, branch `main`, путь `backend/render.yaml`.
2. **Сервисы из blueprint:** `quicksave-api` (Docker) + `quicksave-redis` (free). Если Redis не нужен — закомментируй блок `REDIS_URL` в `render.yaml` перед sync.
3. **Secrets** (Environment → `quicksave-api`):
   - `METRICS_TOKEN` — случайная строка 32+ символов (для `GET /health/metrics` с заголовком `X-Metrics-Token`).
   - Или для dev/staging: `METRICS_PUBLIC=true` (метрики без токена).
   - Опционально: `BILLING_PLAY_VERIFY=1`, `BILLING_DEV_ACCEPT=1` только на staging.
4. **Deploy:** Manual Deploy или auto-deploy on push (Settings → Build & Deploy). После push в `main` с `backend/public/web/` поднимается API + Web PWA на одном домене.
5. **Проверка** (cold start free tier до ~60 с):
   ```bash
   curl https://quicksave-api.onrender.com/health
   curl -I https://quicksave-api.onrender.com/
   ```
   Ожидается: `{"ok":true}` и `200` на `/` (Flutter Web).
6. **Smoke script** (cold-start aware):
   ```bash
   node scripts/smoke-deploy.mjs https://quicksave-api.onrender.com
   # or: cd backend && npm run smoke:deploy
   ```

- [x] Push `main` → Render Blueprint sync (`backend/render.yaml`) — `1c44fc3` on GitHub
- [ ] Blueprint подключён в Render Dashboard
- [ ] Set secrets in Render dashboard: `METRICS_TOKEN` (or `METRICS_PUBLIC=true` for dev)
- [ ] Optional: Redis from blueprint (`REDIS_URL` auto-wired)
- [ ] After deploy: `GET https://quicksave-api.onrender.com/health` → `{ ok: true }`
- [ ] Web PWA: open `https://quicksave-api.onrender.com/` → QuickSave Web dashboard
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

- [x] Generate keystore: `android/quicksave.jks` (alias `quicksave`, 10000 days)
- [x] `android/key.properties` создан (не в Git)
- [x] Пароли сохранены локально: `android/KEYSTORE_CREDENTIALS.local.txt` (**бэкап в password manager!**)
- [x] `flutter build appbundle --release` — release-signed AAB
- [ ] Output: `build/app/outputs/bundle/release/app-release.aab` → загрузить в Play **Internal testing**
- [ ] Play App Signing: при первой загрузке включить Google-managed signing (рекомендуется)

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

- [x] GitHub Actions green: Flutter, Backend, Extension workflows
- [ ] Dependabot PRs reviewed

---

## Known limitations v1.3.1

- **Headless scheduler download** — not implemented; watchlist uses manual check
- **Google Drive backup** — OAuth deferred
- **Library sync** — metadata import/export only (Web), no live sync
- **Play verify** — server stub; set `BILLING_PLAY_VERIFY=1` for production
- Render free tier cold start ~30–60 s
