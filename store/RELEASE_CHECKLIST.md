# QuickSave — чеклист релиза v1.0.0

## Backend (hosted resolver)

- [ ] Задеплоить `backend/` на Render / Fly / VPS (см. `backend/render.yaml`, `backend/README.md`)
- [ ] Проверить `GET https://<your-host>/health` → `{ ok: true }`
- [ ] Проверить `GET /health/metrics` после нескольких `/resolve` запросов
- [ ] (Рекомендуется) Подключить Redis для L2 cache и shared rate limit
- [ ] Обновить `lib/core/constants/app_constants.dart` → `hostedBackendUrl` на production URL
- [ ] Опубликовать privacy policy по HTTPS (GitHub Pages / свой домен) и указать URL в Play Console

## Android signing

- [ ] `keytool -genkey -v -keystore quicksave.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quicksave`
- [ ] Скопировать `android/key.properties.example` → `android/key.properties`
- [ ] `flutter build appbundle --release` (Play Store) **или** `flutter build apk --release` (sideload)
- [ ] Debug smoke: `flutter build apk --debug` — для локальной проверки без keystore
- [ ] Release APK/AAB подписывается только при наличии `key.properties`; без него используйте debug APK
- [ ] Проверить APK/AAB на реальном устройстве (Share, Gallery, widget, QS tile)

## Google Play Console

- [ ] Тексты: `store/listing_en.md`, `store/listing_ru.md`
- [ ] Privacy policy: `store/privacy_policy.md` (+ hosted URL)
- [ ] Скриншоты: Home, Preview, History, Settings, Share sheet (мин. 2 языка)
- [ ] Feature graphic 1024×500
- [ ] App icon 512×512 (adaptive уже в проекте)
- [ ] Категория: Tools / Productivity
- [ ] Content rating questionnaire
- [ ] Data safety: no account, no personal data collection, network only for resolve

## QA перед публикацией

- [ ] Share Intent из Instagram → auto-download → Gallery (если включено)
- [ ] Профиль @username → batch select → download
- [ ] Quick Settings tile + clipboard link
- [ ] Home screen widget открывает приложение
- [ ] Pro demo key `QS-PRO-DEMO1` → scheduler UI, ZIP export
- [ ] Offline / backend down → понятные ошибки
- [ ] `flutter test` (106) и `cd backend && npm test` (105)

## CI

- [ ] GitHub Actions green на `main`
- [ ] Dependabot PRs reviewed

## Известные ограничения v1.0

- Планировщик Pro регистрирует профили и Workmanager-задачу; **headless auto-download в фоне без открытия приложения не реализован** — пользователь видит UI списка профилей, ежедневный sync — инфраструктура.
- Pro-лицензия проверяется локально по формату ключа (+ demo keys); без серверной активации.
- Hosted backend на free tier может «засыпать» — первый запрос после простоя ~30–60 с.
