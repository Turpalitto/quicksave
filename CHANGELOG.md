# Changelog

Все значимые изменения в проекте документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
этот проект следует [Semantic Versioning](https://semver.org/lang/ru/).

## [1.1.0] - 2026-06-21

### Added
- Backend resolver modularization (`urlNormalizer`, `upstreamClient`, `postExtractor`, `storyExtractor`, `profileExtractorFacade`, `resultAssembler`, `resolverErrors`) + golden tests.
- Production **download queue**: multi-task, pause/resume/cancel, retry w/ exponential backoff, preflight size check.
- **Media library**: search (caption/author/fileName), filters (video/photo/stories/profiles), collections, dedupe, failed item tracking, v1→v2 history migration.
- Accessibility tests (semantics, tap targets).
- CI: format check, coverage artifact, release APK build; issue/PR templates.

### Changed
- Unified i18n via `flutter gen-l10n` (removed analyzer exclude for generated l10n).
- Privacy policy: retention, legal basis, rights flow, telemetry, self-hosted disclosure.

## [1.0.0] - 2026-06-21

Production-ready release: hosted resolver, Gallery save, Pro tier, store assets.

### Added
- **Hosted backend** — zero-config `BackendMode.hosted` + `hostedBackendUrl` default.
- **Gallery save** — MediaStore integration (`GalleryHelper.kt`, setting `saveToGallery`).
- **Auto-download** — Share Intent → background download + pop to Home on success.
- **Quick Settings tile** + **Home screen widget** (native Kotlin).
- **Onboarding** — first-run tips (Share, QS tile, Gallery).
- **History** — caption, post date, copy caption, batch partial success UX.
- **Pro** — local license `QS-PRO-XXXX`, demo keys, scheduler UI, ZIP export, self-hosted backend unlock.
- **Backend** — Redis L2 resolve cache, `/health/metrics`, `render.yaml` for deploy.
- **Store** — `store/listing_*.md`, `privacy_policy.md`, `RELEASE_CHECKLIST.md`.
- **Web/PWA** — updated `manifest.json` and `index.html`.

### Changed
- Defaults: `autoDownload`, `saveToGallery`, `watchClipboard` ON.
- Removed unused `home_widget` dependency (native widget used instead).
- `workmanager` 0.5 → **0.9** — fixes Android release/debug build with current Flutter embedding.
- README and backend docs updated for release workflow.

### Known limitations
- Pro scheduler: profile list + Workmanager registered; headless download without opening app not implemented in v1.0.
- Pro license: format validation only (no server activation).

## [Unreleased]

### Added
- Preview/Settings semantics labels; expanded accessibility tests; download queue panel widget test.
- `historyAddedToCollection` l10n for add-to-collection snackbar (distinct from collection created).

### Fixed — первая успешная сборка APK
- `android/app/build.gradle`: включён `coreLibraryDesugaringEnabled true` +
  добавлена зависимость `com.android.tools:desugar_jdk_libs:2.1.4` —
  `flutter_local_notifications` требует core library desugaring (использует
  `java.time` API на Android < 26).
- `android/gradle/wrapper/gradle-wrapper.properties`: Gradle 8.11.1 → **8.14.2**
  (Flutter 3.44 выводит deprecation warning для < 8.14.0).
- `android/settings.gradle`: AGP 8.9.1 → **8.11.1**, Kotlin 2.0.21 → **2.2.20**
  (Flutter 3.44 выводит deprecation warning для старых версий).
- Создана символическая ссылка `C:\jdk21` → `C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot`
  — обходит ограничение sdkmanager.bat при JAVA_HOME с пробелами в пути.
- NDK 28.2.13676358 установлен через sdkmanager (первая попытка дала corrupt zip,
  потребовалась очистка `.temp` и повторная установка).
- AGP 8.11.1 автоматически скачал build-tools;35.0.0, platforms 33/34/35, CMake 3.22.1.

**Результат:** `flutter build apk --debug` — **✅ успех, app-debug.apk 157.7 МБ**.

### Added — hygiene/релиз-готовность
- `analysis_options.yaml` приведён к production-конфигу: поверх `flutter_lints`
  добавлены `strict-casts`/`strict-raw-types`, `missing_required_param`/
  `missing_return` как error, `prefer_final_locals`, `prefer_single_quotes`,
  `cancel_subscriptions`/`close_sinks` и др. `app_localizations.dart` исключён
  из анализа (ручная реализация).
- Релизное подписание: `build.gradle` читает `android/key.properties`
  (если есть) → `signingConfigs.release`; иначе откат на debug-ключ, чтобы
  CI/debug-сборки не падали. Добавлен шаблон `key.properties.example`.
- `backend/.gitignore` создан (раньше отсутствовал).

### Fixed
- Deprecated `Color.withOpacity()` → `withValues(alpha:)` (deprecated с
  Flutter 3.27; CI использует 3.44). 3 места: `app_theme.dart`,
  `home_screen.dart` (2).
- Конфликт локализации: `pubspec.yaml` `generate: true` включал бы авто-генерацию
  `AppLocalizations` из ARB и конфликтовал с ручной реализацией
  `lib/l10n/app_localizations.dart` → поставлен `generate: false`.
- CI `flutter.yml`: убраны два мёртвых шага `scripts/generate_icons.sh`
  (папки `scripts/` в репозитории нет; PNG-иконки уже закоммичены).

### Fixed — Flutter 3.44 (компиляция + линтер)
Первый прогон `flutter analyze` на реальном SDK 3.44 вскрыл, что код никогда
не компилировался (API `ThemeData.cardTheme` изменён в 3.44: `CardTheme`
удалён, ожидается `CardThemeData`). 9 файлов:
- `app_theme.dart`: `CardTheme` → `CardThemeData`.
- `settings_provider.dart`, `settings_screen.dart`: импорты `../domain/` →
  `../../domain/` (файлы в `presentation/providers` и `presentation/screens`).
- `download_provider_test.dart`, `history_provider_test.dart`,
  `settings_provider_test.dart`: путь к `mock_setup.dart` `../helpers/` →
  `../../helpers/`.
- `app.dart`: удалены неиспользуемые импорты (`flutter_localizations`,
  `app_constants`).
- `strings.dart`: удалён неиспользуемый getter `_raw`.
- `download_provider.dart`: unnecessary lambda `(ref) => DownloadNotifier(ref)`
  → tearoff `DownloadNotifier.new`.
- `download_provider_test.dart`: удалён неиспользуемый импорт `settings_provider`.
- Результат `flutter analyze`: 27 issues → **0 ошибок, 0 предупреждений,
  2 info** (`RadioListTile.groupValue/onChanged` deprecated — замена
  `RadioGroup` пока не в стабильном Flutter 3.44, не исправимо).

### Fixed — реальный прогон `flutter test` на SDK 3.44.2 (4 бага)
`flutter analyze` чист, потому что `analysis_options.yaml` исключает
`app_localizations.dart`. Но `flutter test` компилирует всё — и вскрыл
4 бага, скрытых исключением из анализа:
- `lib/l10n/app_localizations.dart`: отсутствовали импорты —
  `package:flutter_localizations` (`GlobalMaterialLocalizations` /
  `GlobalWidgetsLocalizations` / `GlobalCupertinoLocalizations`) и
  `package:flutter/foundation` (`SynchronousFuture`). Widget-тесты не
  компилировались. Импорты добавлены.
- `test/helpers/mock_setup.dart`: `initPlatformMocks` не вызывал
  `StorageService.instance.init()` после `SharedPreferences.setMockInitialValues`
  → provider-тесты (download/history/settings) падали с
  «StorageService.init() не вызван». Функция стала `Future<void>`, init добавлен.
- `lib/core/utils/validators.dart`: `normalize` использовал
  `uri.replace(queryParameters: {}).toString()`, а Dart Uri сериализует пустую
  query-карту как `?` → нормализованный URL получал хвост `/?` и не матчился
  строгим regex в `isValidInstagramUrl` (валидные reel/p/tv отклонялись).
  Заменено на детерминированное отсечение fragment→query→trailing slash.
  Плюс `extractInstagramUrl` не захватывал trailing slash (тесты ждут его) —
  в regex добавлен `\/?`.
- `test/features/history/history_provider_test.dart`: утечка состояния между
  тестами (mock SharedPreferences живёт весь файл). Добавлен `setUp` с
  `HistoryRepository.instance.clear()`.

### Установка Flutter SDK
- Flutter 3.44.2 (Dart 3.12.2) развёрнут в `C:\flutter`,
  `C:\flutter\bin` добавлен в пользовательский PATH.
- **Результат:** `flutter analyze` — 0 ошибок/0 предупреждений/2 info;
  `flutter test` — **73 теста, все зелёные**.
- Android SDK/Studio пока не установлены — `flutter build apk` недоступен.

### Changed — платформа/CI выровнены под 3.44
- `pubspec.yaml`: `sdk: ">=3.4.0 <4.0.0"` → `">=3.10.0 <4.0.0"`;
  `flutter: ">=3.22.0"` → `">=3.44.0 <4.0.0"` (код требует `CardThemeData`).
- CI `flutter.yml`: `flutter-version: 3.29.0` → `3.44.0` (оба джоба: test и
  build), обновлён комментарий. Без этого CI падал бы на `CardThemeData`.

### Changed
- `instagram_resolver.dart`: дублированный `switch` по коду ошибки
  (в 2xx- и 4xx/5xx-ветках) извлечён в приватный `_exceptionForError()`.
  Поведение сохранено 1:1 (неизвестный код на 2xx → ResolverException,
  на 4xx/5xx → ServerException); тесты совместимы.
- Корневой `.gitignore` расширен: `*.keystore`/`*.jks`, `coverage/`,
  `node_modules/`, `.fvm/`, `build_*/`, env-файлы, debug/profile артефакты
  Android.
- README приведён в соответствие с реальностью: убраны несуществующие
  `scripts/generate_icons.sh` и `docs/`; дерево обновлено (31 dart-файл,
  foreground-сервис, `analysis_options.yaml`, `key.properties.example`);
  добавлена секция «Релизное подписание».

### Changed — платформа Android 11–16
- `minSdk` 23 → **30** (Android 11). Ниже не поддерживается: scoped storage
  упрощает работу с файлами, runtime storage-permission не нужны.
- `compileSdk`/`targetSdk` 34 → **36** (Android 16).
- Toolchain поднят под API 36: AGP 8.1.0 → **8.9.1**, Gradle 8.3 → **8.11.1**,
  Kotlin 1.9.10 → **2.0.21**, CI Flutter 3.24 → **3.44.0** (AGP 8.9.1 — минимум
  для compileSdk 36 по данным developer.android.com; 3.44 также требуется
  коду — `CardThemeData`). Dart SDK 3.4 → **3.10**.
- Убран `multiDexEnabled` + зависимость androidx.multidex — нативный multidex
  доступен с minSdk 21, для minSdk 30 не нужен.
- `enableJetifier` оставлен как есть (безопасно; все зависимости уже AndroidX).

### Removed (legacy storage для Android < 11)
- `WRITE_EXTERNAL_STORAGE` (maxSdk 28) и `READ_EXTERNAL_STORAGE` (maxSdk 32)
  из AndroidManifest — не нужны для app-specific external dir на Android 11+.
- `requestLegacyExternalStorage="true"` — работал только до Android 10 и
  конфликтовал со scoped storage.
- `DownloadService._ensureStoragePermission()` и `_androidSdkInt()` — запрос
  storage-permission был только для SDK ≤28, теперь недостижим. Убран import
  `permission_handler` из download_service (остался в notification_service для
  POST_NOTIFICATIONS на Android 13+).

### Added
- Foreground-сервис для длительных скачиваний (Android 14+ compliance):
  Kotlin `DownloadForegroundService` + MethodChannel `quicksave/download_fg`,
  ongoing-уведомление с процентом, троттлинг обновлений, корректное завершение
  в `finally`. Держит процесс живым при сворачивании приложения.
- Многостратегийный резолвер бэкенда: og:video* → JSON-LD `VideoObject` →
  embedded `video_url` → `video_versions[]` → `playable_url` → GraphQL
  fallback (`?__a=1&__d=dis`). Ротация User-Agent (3 UA). Расширенный
  детект login-wall. Заметно повышает шанс получить прямую ссылку для
  публичных постов, где `og:video` отсутствует.
- Обработка `rate_limited` (429) на клиенте: `RateLimitedException` →
  `RateLimitedFailure` с человекочитаемым сообщением.
- Поддержка коротких ссылок `instagr.am` на сервере (PUBLIC_PATTERNS) —
  теперь клиент и сервер принимают одинаковый набор доменов.
- Интеграционные тесты резолвера с реалистичными HTML-фикстурами Instagram
  (имитация настоящих ответов) — покрывают все стратегии извлечения.

### Fixed
- CI `flutter.yml`: неверный `working-directory: quicksave` (репозиторий
  уже является корнем Flutter-проекта) — убран; путь артефакта APK исправлен;
  шаг генерации иконок сделан необязательным (PNG уже закоммичены).
- Backend `resolve.test.js`: неверный require `./routes/resolve` → `./resolve`
  (test-suite не запускался).
- Backend error handler: malformed JSON (`entity.parse.failed`) возвращал
  500 "internal" вместо 400 — теперь 400 `invalid_json`.
- Backend `extractAuthor`: порядок regex-паттернов — "Reel by"/"Video by"
  теперь проверяются раньше generic "X on Instagram", иначе жадный `(.+?)`
  съедал префикс ("Reel by Alice" вместо "Alice").
- Клиентская валидация `Validators.isValidInstagramUrl` была мягкой (`contains`)
  и расходилась с серверной строгой — теперь строгий anchored regex после
  нормализации, зеркалирует серверные PUBLIC_PATTERNS. Спрятанный Instagram-
  паттерн в query стороннего сайта больше не проходит валидацию на клиенте.

### Tests
- Backend-тесты резолвера переписаны с моком axios: success (og:video,
  embedded `video_url`, GraphQL fallback, JSON-LD), 404, private/login-wall,
  401, network error, ротация UA, чистые функции. Покрытие: 18 → 63 теста.
- Интеграционные тесты с HTML-фикстурами: реалистичные ответы Instagram,
  проверка извлечения URL через каждую стратегию + нормализация query.
- `index.test.js`: malformed JSON → 400, payload too large → 413.
- `errors_test.dart`: добавлен кейс `RateLimitedException → RateLimitedFailure`.
- `validators_test.dart`: edge-кейсы строгой валидации (паттерн в query,
  без протокола, instagr.am, stories с shortcode, пустая строка).

### Verified (live server E2E)
- `/health`, `/health/ready` → 200.
- Валидация: empty/non-instagram/profile/stories/hidden-pattern → 400 invalid_url.
- Malformed JSON → 400 invalid_json.
- Rate limit: >30 req/min → 429 rate_limited (тело совпадает с клиентским маппингом).
- Реальный запрос к Instagram → структурированный ответ без 500-крашей.

### Планируется
- Поддержка Reels из Facebook
- История в виде сетки (2 колонки)
- Шеринг в истории Instagram

## [1.0.0] - 2024

### Added
- Material 3 дизайн с поддержкой светлой и тёмной темы
- Android Share Intent для получения ссылок из Instagram
- Резолвинг публичных Instagram-постов через backend (`POST /resolve`)
- Скачивание видео с прогрессом через Dio
- Возобновление прерванной загрузки (HTTP Range)
- Локальные уведомления о завершении/ошибке (Android 13+ runtime permission)
- История скачиваний с превью, поиском и swipe-to-delete
- Открытие скачанного видео через системный плеер
- Повторный шеринг сохранённого видео
- Локализация: русский и английский
- Темы: как в системе / светлая / тёмная
- Настройки: backend URL, автоскачивание, уведомления, история, тема
- Material 3 surface tonal palette
- Adaptive launcher icon + monochrome (Android 13+)
- PNG launcher icons для всех плотностей
- Network security config (cleartext только для LAN/dev)
- Auto backup rules (бэкап настроек, без файлов)
- Unit и widget тесты для критических компонентов
- Backend tests (Jest + supertest)
- GitHub Actions CI/CD (Flutter analyze + test + build, backend tests)
- Dependabot для обновления зависимостей

### Security
- Не сохраняем cookies, не логинимся в Instagram
- Только публичные посты (regex-валидация клиент + сервер)
- Понятная ошибка если Instagram не отдаёт прямую ссылку

## [0.1.0] - Initial

### Added
- Базовая структура проекта
