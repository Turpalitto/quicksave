# Архитектура QuickSave

## Слои

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation (UI)                                          │
│  - HomeScreen, PreviewScreen, HistoryScreen, SettingsScreen │
│  - Riverpod ConsumerStatefulWidget / ConsumerWidget         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  State Management (Riverpod)                                │
│  - DownloadNotifier (sealed DownloadState)                  │
│  - HistoryNotifier (List<DownloadItem>)                     │
│  - SettingsNotifier (AppSettings)                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Domain (Models)                                            │
│  - VideoInfo, DownloadItem, AppSettings                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Data (Repositories + DataSources)                          │
│  - HistoryRepository, SettingsRepository                    │
│  - InstagramResolver (HTTP)                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Services (Platform integration)                            │
│  - IntentService (Share Intent)                             │
│  - DownloadService (Dio + file system)                      │
│  - NotificationService (flutter_local_notifications)        │
│  - StorageService (SharedPreferences)                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Platform (Android)                                         │
│  - MainActivity.kt (MethodChannel "quicksave/share_intent")│
│  - AndroidManifest.xml (intent-filter, permissions)         │
└─────────────────────────────────────────────────────────────┘
```

## Поток данных: Share Intent → Скачивание

```
[Instagram]
   │  user taps "Поделиться" → QuickSave
   ▼
[Android Intent system]
   │  ACTION_SEND + EXTRA_TEXT
   ▼
[MainActivity.kt]
   │  MethodChannel.invokeMethod("onSharedText", text)
   ▼
[IntentService (Dart)]
   │  broadcast to stream + store in _pending
   ▼
[HomeScreen]
   │  consumePending() → validate URL → open PreviewScreen
   ▼
[PreviewScreen]
   │  downloadProvider.resolve(url)
   ▼
[DownloadNotifier.resolve()]
   │  InstagramResolver.resolve(url, backendUrl)
   ▼
[InstagramResolver]
   │  Dio POST {backendUrl}/resolve {url: ...}
   ▼
[Backend Express :3000]
   │  routes/resolve → instagramResolver
   │  fetch instagram.com HTML → extract og:video
   ▼
[VideoInfo] → DownloadResolved state
   │  user taps "Скачать"
   ▼
[DownloadNotifier.download()]
   │  DownloadService.download(url, fileName)
   ▼
[DownloadService]
   │  Dio.download(url, target.part)  [supports Range resume]
   │  File.rename(.part → final)
   ▼
[DownloadSuccess state] + historyProvider.add() + NotificationService.show()
```

## Обработка ошибок

```
Errors → AppException (sealed)
   ↓ catch
Failure (sealed, UI-friendly)
   ↓ mapExceptionToFailure
UI message
```

| Exception            | Failure             | UI сообщение                                |
| -------------------- | ------------------- | ------------------------------------------ |
| NoInternetException  | NoInternetFailure   | Нет подключения к интернету                |
| InvalidUrlException  | InvalidUrlFailure   | Неверная ссылка Instagram                  |
| PrivatePostException | PrivatePostFailure  | Пост приватный или недоступен              |
| ResolverException    | ResolverFailure     | Не удалось получить прямую ссылку          |
| ServerException      | ServerFailure       | Ошибка сервера                             |
| NoSpaceException     | NoSpaceFailure      | Недостаточно места                         |
| FileWriteException   | FileWriteFailure    | Не удалось сохранить файл                  |
| Cancelled            | CancelledFailure    | Скачивание отменено                        |
| Unknown              | UnknownFailure      | Неизвестная ошибка                         |

## Стратегия хранения файлов

Используется **app-specific external dir**:
```
/storage/emulated/0/Android/data/com.quicksave.app/files/QuickSave/
```

**Почему этот путь:**
- ✅ Не требует runtime storage-разрешений (scoped storage, minSdk 30 / Android 11+).
- ✅ Виден пользователю через «Файлы» на устройстве.
- ✅ Удаляется автоматически при удалении приложения.
- ✅ Работает надёжно на Android 11–16.

**Альтернативы, которые мы НЕ используем:**
- ❌ Публичный `Download/` — требует MediaStore на Android 11+.
- ❌ `/sdcard/Download/` — запрещено scoped storage.

## Возобновление загрузки

DownloadService поддерживает resume через HTTP Range header:
1. Скачивание пишется в файл `<name>.part`.
2. При обрыве `.part` остаётся на диске.
3. При повторной попытке Dio получает `Range: bytes=<existing>-`.
4. Сервер отдаёт только недостающие байты.
5. По завершении `.part` атомарно переименовывается в `<name>.mp4`.

Если сервер не поддерживает Range (416) — файл удаляется и загрузка начинается заново.

## Локализация

- ARB файлы в `lib/l10n/`: `app_en.arb`, `app_ru.arb`.
- Сгенерированный `app_localizations.dart` (предоставлен вручную).
- Helper `Strings.of(context)` в `lib/core/utils/strings.dart` — fallback на русский если локализация недоступна.
- Добавление нового языка: создать `app_<lang>.arb` и добавить в `AppLocalizations._localizedValues`.

## Тестирование

```
test/
├── utils/                        # Validators, formatters
├── features/
│   ├── settings/                 # Settings provider
│   ├── history/                  # History provider
│   └── downloader/               # Download provider
├── core/                         # Error mapping
├── widgets/                      # Home screen
└── helpers/                      # Mock setup
```

## Безопасность

1. **Не логинимся в Instagram** — backend только читает публичную HTML.
2. **Не сохраняем cookies** — HTTP-клиент stateless.
3. **Не обходим антибот** — используем только то, что Instagram отдаёт публично.
4. **Не скачиваем приватный контент** — regex-валидация `/reel|p|tv/` + проверка `og:video` на сервере.
5. **Cleartext только в debug** — `network_security_config.xml` разрешает HTTP только для LAN/10.0.2.2 в debug-overrides.
6. **Бэкап без файлов** — `backup_rules.xml` исключает `QuickSave/` из auto-backup.

## Производительность

- **Прогресс через `onReceiveProgress`** — обновление UI без перерасчёта layout.
- **`AnimatedSwitcher`** — плавные переходы между состояниями.
- **`ListView.builder`** (через `.separated`) — ленивая загрузка списка истории.
- **`ConsumerStatefulWidget`** только где нужны lifecycle hooks (PreviewScreen, HomeScreen, HistoryScreen).
- **`ConsumerWidget`** для всего остального — минимизация boilerplate.
