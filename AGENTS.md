# AGENTS.md — QuickSave

## Что это

Android-приложение (Flutter) для скачивания публичных видео из Instagram
через Share Intent. Состоит из клиентского приложения и Node.js бэкенд-резолвера.

**Платформа:** Android 11 (API 30) — Android 16 (API 36)

## Структура проекта

```
quicksave/
├── lib/                          # Flutter (Dart) исходники
│   ├── core/
│   │   ├── constants/            # app_constants.dart
│   │   ├── errors/               # exceptions.dart, failures.dart (sealed-типы)
│   │   ├── theme/                # Material 3 темы (light/dark)
│   │   ├── utils/                # validators.dart, formatters.dart, strings.dart
│   │   └── widgets/              # error_view, loading_view, empty_view
│   ├── features/
│   │   ├── downloader/
│   │   │   ├── data/             # instagram_resolver.dart (HTTP → backend POST /resolve)
│   │   │   ├── domain/           # video_info.dart (модель)
│   │   │   └── presentation/
│   │   │       ├── providers/    # download_provider.dart (Riverpod StateNotifier)
│   │   │       └── screens/      # preview_screen.dart
│   │   ├── history/              # история скачиваний (SharedPreferences)
│   │   ├── home/                 # главный экран (ввод URL / Share Intent)
│   │   └── settings/             # настройки (backend URL, тема, автоскачивание)
│   ├── l10n/                     # локализация (ru/en)
│   └── services/
│       ├── download_service.dart     # Dio + resume (HTTP Range), .part файлы
│       ├── foreground_service.dart   # MethodChannel → Kotlin foreground service
│       ├── intent_service.dart       # Share Intent через MethodChannel
│       ├── notification_service.dart # flutter_local_notifications
│       └── storage_service.dart      # SharedPreferences
├── android/                      # Android-конфиг
│   ├── app/
│   │   ├── build.gradle          # minSdk 30, targetSdk 36, AGP 8.9.1
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/.../
│   │           ├── MainActivity.kt
│   │           └── DownloadForegroundService.kt
│   ├── settings.gradle           # AGP 8.9.1, Kotlin 2.0.21
│   ├── gradle/wrapper/           # Gradle 8.11.1
│   └── gradle.properties
├── backend/                      # Node.js Express сервер
│   ├── src/
│   │   ├── index.js              # Express app, rate limiter, error handler
│   │   ├── routes/resolve.js     # POST /resolve route
│   │   └── services/
│   │       ├── instagramResolver.js           # Резолвер (многостратегийный)
│   │       ├── instagramResolver.test.js      # Unit tests (mock axios)
│   │       ├── instagramResolver.integration.test.js  # Integration tests (HTML fixtures)
│   │       └── __fixtures__/instagramHtml.js  # Реалистичные HTML-фикстуры Instagram
│   └── package.json
├── .github/workflows/
│   ├── flutter.yml               # Flutter analyze + test + build APK
│   └── backend.yml               # Backend tests + syntax check
├── test/                         # Flutter unit/widget тесты
├── CHANGELOG.md
├── ARCHITECTURE.md
└── AGENTS.md                     # ← этот файл
```

## Как запускать

### Backend
```bash
cd backend
npm install
npm test              # 63 тестов, все зелёные
npm start             # http://localhost:3000
```

### Flutter (Android)
```bash
# Flutter 3.44.2 уже установлен в C:\flutter и в PATH.
# JAVA_HOME=C:\jdk21 (Junction → Eclipse Adoptium JDK 21)
# ANDROID_HOME=C:\Android\Sdk
flutter pub get
flutter analyze      # 0 ошибок, 0 предупреждений, 2 info
flutter test         # 73 теста, все зелёные
flutter build apk --debug   # ✅ OK — app-debug.apk 157.7 МБ
flutter build apk --release # требует key.properties (подпись)
```

## Архитектура

### Поток данных
```
Share Intent → MainActivity (Kotlin) → MethodChannel → IntentService
  → preview_screen → download_provider
    → instagram_resolver → backend POST /resolve → instagramResolver.js
      → og:video / JSON-LD / embedded video_url / video_versions / GraphQL
    → download_service.dart (Dio + HTTP Range resume)
      → DownloadForegroundService.kt (ongoing notification)
      → notification_service (complete/error)
      → history_repository (SharedPreferences)
```

### Клиент
- **Riverpod** для state management
- **sealed-типы** для состояний (Loading/Success/Failure) и ошибок (AppException/Failure)
- **Слой data/domain/presentation** в каждом feature

### Бэкенд
- **Express** с helmet, cors, rate-limit (30 req/min)
- **Многостратегийный резолвер** Instagram (цепочка с fallback):
  1. og:video:secure_url / og:video / og:video:url
  2. JSON-LD VideoObject.contentUrl
  3. Embedded `"video_url"` (JSON escape `\/`)
  4. `"video_versions[]"` array
  5. `"playable_url"` / `"playable_url_dash"`
  6. GraphQL fallback `?__a=1&__d=dis` → recursive JSON search
- **Ротация 3 User-Agent** (мобильный Chrome, Safari, десктопный Chrome)
- **Расширенный детект login wall** (6 маркеров)

## Тестирование

### Backend: 63 тестов
- `instagramResolver.test.js` — unit tests с моком axios (strategy chain, UA rotation, login wall, 404, network error)
- `instagramResolver.integration.test.js` — интеграционные тесты с реалистичными HTML-фикстурами Instagram (im的真实 ответы)
- `routes/resolve.test.js` — HTTP-тесты маршрута (валидация, ошибки)
- `index.test.js` — health endpoints, malformed JSON (400), payload too large (413)

### E2E (live server)
Прогонялся через curl against реального backend:
- `/health`, `/health/ready` → 200
- Валидация: empty/body/example/profile/stories/hidden-pattern → 400 invalid_url
- Malformed JSON → 400 invalid_json
- Rate limiting: >30 req/min → 429 rate_limited
- Реальный запрос к Instagram → структурированный ответ (not_found/private/success)
- instagr.am short URLs → редирект → корректный ответ

### Flutter: тесты есть в test/
Покрывают validators, formatters, exceptions/failures, download/history/
settings providers, home screen widget. **`flutter analyze`** на SDK 3.44.2:
0 ошибок, 0 предупреждений, 2 info (deprecated RadioListTile — без доступной
замены). **`flutter test`** на SDK 3.44.2: **73 теста, все зелёные**.

**Окружение:** Flutter 3.44.2 (Dart 3.12.2) установлен в `C:\flutter`,
`C:\flutter\bin` добавлен в пользовательский PATH. Android SDK/Studio не
установлены — поэтому `flutter build apk` пока недоступен (требует Android SDK).

## Что было сделано (сводка изменений)

### Backend
1. **Усилен резолвер Instagram** — заменён одиночный og:video на цепочку 6 стратегий с fallback + ротация 3 UA + GraphQL
2. **Исправлен extractAuthor** — "Reel by"/"Video by" проверяются раньше generic "X on Instagram" (жадный regex съедал префикс)
3. **Исправлен error handler** — malformed JSON (entity.parse.failed) возвращал 500 вместо 400 → теперь 400 invalid_json
4. **Добавлен instagr.am** в PUBLIC_PATTERNS (клиент принимал, сервер отвергал)
5. **Написаны интеграционные тесты** с реалистичными HTML-фикстурами Instagram
6. **Написаны unit tests** с моком axios (все стратегии извлечения)
7. **Починен resolve.test.js** — неверный require путь

### Flutter (клиент)
1. **rate_limited (429)** — RateLimitedException → RateLimitedFailure с сообщением
2. **Строгая валидация URL** — заменён мягкий `contains` на anchored regex (зеркало сервера)
3. **Foreground-сервис** —.foreground_service.dart + MethodChannel + Kotlin DownloadForegroundService
4. **Упрощён download_service** — убрана storage-permission логика (недостижима для API 30+)

### Flutter 3.44 (компиляция + линтер, 9 файлов)
Первый прогон `flutter analyze` на реальном SDK (3.44) вскрыл, что код никогда
не компилировался. Исправлено:
1. **app_theme.dart** — `CardTheme` → `CardThemeData` (API ThemeData.cardTheme
   изменён в 3.44: CardTheme удалён)
2. **settings_provider.dart / settings_screen.dart** — неверные относительные
   пути импорта `../domain/` → `../../domain/` (файлы в presentation/providers
   и presentation/screens)
3. **3 теста** (download/history/settings_provider_test) — путь к
   mock_setup.dart `../helpers/` → `../../helpers/`
4. **app.dart** — удалены неиспользуемые импорты (flutter_localizations, app_constants)
5. **strings.dart** — удалён неиспользуемый getter `_raw`
6. **download_provider.dart:167** — unnecessary lambda
   `(ref) => DownloadNotifier(ref)` → tearoff `DownloadNotifier.new`
7. **download_provider_test.dart** — удалён неиспользуемый импорт settings_provider

**Результат `flutter analyze`:** 27 issues → **0 ошибок, 0 предупреждений,
2 info** (deprecated `RadioListTile.groupValue/onChanged` — замена `RadioGroup`
пока недоступна в стабильном Flutter 3.44, не исправимо без поломки сборки).

### Flutter 3.44 — реальный прогон `flutter test` (4 бага, SDK установлен)
`flutter analyze` чист, потому что `analysis_options.yaml` исключает
`app_localizations.dart` из анализа. Но `flutter test` компилирует всё — и
вскрыл 4 настоящих бага (другая IDE заявила успех только по `analyze`):
1. **app_localizations.dart** — отсутствовали импорты: `Global*Localizations`
   (нужен `package:flutter_localizations`) и `SynchronousFuture` (нужен
   `package:flutter/foundation`). → widget-тесты не компилировались.
2. **mock_setup.dart** — `initPlatformMocks` не вызывал
   `StorageService.instance.init()` после установки mock SharedPreferences →
   download/history/settings provider-тесты падали с
   «StorageService.init() не вызван». Сделан async, init добавлен.
3. **validators.dart** — `normalize` использовал
   `uri.replace(queryParameters: {}).toString()`, а Dart Uri сериализует
   пустую query-карту как `?`, из-за чего URL получал хвост `/?` и не матчился
   строгим regex в `isValidInstagramUrl` (валидные reel/p/tv отклонялись).
   Заменено на детерминированное отсечение fragment→query→trailing slash.
   Плюс `extractInstagramUrl` не захватывал trailing slash (тесты ждут его) —
   добавлен `\/?`.
4. **history_provider_test.dart** — утечка состояния между тестами: mock
   SharedPreferences живёт весь файл, элементы из теста `add` попадали в
   тест `remove`. Добавлен `setUp` с `HistoryRepository.clear()`.

**Результат:** `flutter analyze` — 0 ошибок/0 предупреждений/2 info;
`flutter test` — **73 теста, все зелёные**.

### Android / Toolchain
1. **minSdk 23 → 30** (Android 11)
2. **compileSdk/targetSdk 34 → 36** (Android 16)
3. **AGP 8.1.0 → 8.9.1, Gradle 8.3 → 8.11.1, Kotlin 1.9.10 → 2.0.21**
4. **CI Flutter 3.24 → 3.44.0** (Dart 3.10) — код требует 3.44 (`CardThemeData`,
   `withValues`); pubspec: `flutter: ">=3.44.0 <4.0.0"`, `sdk: ">=3.10.0 <4.0.0"`
5. **Убраны legacy storage permissions** (WRITE/READ_EXTERNAL_STORAGE, requestLegacyExternalStorage, multidex)

### CI
1. **Исправлен flutter.yml** — неверный working-directory, путь артефакта, необязательная генерация иконок

### Документация
1. **CHANGELOG.md** — подробные записи всех изменений
2. **README.md** — платформа Android 11–16, таблица технологий
3. **ARCHITECTURE.md** — обновлена стратегия хранения

## Важные замечания для следующего шага

1. **`flutter build apk --debug` — РАБОТАЕТ** ✅  
   APK собран: `build\app\outputs\flutter-apk\app-debug.apk` (157.7 МБ).  
   Toolchain: Flutter 3.44.2, Dart 3.12.2, JDK 21, AGP 8.11.1, Gradle 8.14.2,
   Kotlin 2.2.20, NDK 28.2.13676358, compileSdk/targetSdk 36, minSdk 30.

2. **core library desugaring включён** — `coreLibraryDesugaringEnabled true` +
   `desugar_jdk_libs:2.1.4` в `android/app/build.gradle`. Нужно `flutter_local_notifications`.

3. **Символическая ссылка C:\jdk21** — Junction на Eclipse Adoptium JDK 21
   (обход пробелов в пути для sdkmanager.bat). JAVA_HOME = C:\jdk21.

2. **Toolchain 3.44** — CI и pubspec выровнены на Flutter 3.44.0 / Dart 3.10
   (код требует `CardThemeData`). AGP 8.9.1 + Gradle 8.11.1 + compileSdk 36
   поддерживаются Flutter 3.29+, так что 3.44 покрывает всё. Реальная сборка
   APK — финальная проверка совместимости плагинов (dio, riverpod,
   flutter_local_notifications, open_filex, share_plus) с 3.44.

3. **Edge-to-edge** (Android 15+, targetSdk 35+) — Flutter включает
   edge-to-edge по умолчанию. Scaffold+AppBar (как здесь) обычно работает
   корректно, но экраны без AppBar могут потребовать SafeArea.

4. **2 info в analyze** — `RadioListTile.groupValue/onChanged` deprecated в
   3.44, замена `RadioGroup` ещё не в стабильном канале. Не трогать до
   появления RadioGroup — иначе сборка сломается.

5. **Instagram resolver** — цепочка стратегий повышает шанс успеха, но
   Instagram борется с парсингом. Процент успеха зависит от поста/региона/
   времени — ограничение подхода, а не кода.

6. **Полезные команды (Flutter на PATH: `C:\flutter\bin`):**
   - `npm test` — backend тесты (63)
   - `node --check src/**/*.js` — синтаксис JS
   - `flutter analyze` — статический анализ Dart (требует SDK 3.44)
   - `flutter test` — Dart тесты (73)
   - `flutter build apk --debug` — сборка APK (требует Android SDK)
