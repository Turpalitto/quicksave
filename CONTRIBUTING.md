# Contributing

Спасибо за интерес к QuickSave! Вот несколько правил для контрибьюторов.

## Workflow

1. Fork → branch → commit → pull request.
2. Имя ветки: `feat/...`, `fix/...`, `chore/...`, `docs/...`.
3. Один PR = одно изменение.
4. Перед PR запустите:
   ```bash
   cd quicksave && flutter analyze && flutter test
   cd backend && npm test
   ```

## Стиль кода

### Dart / Flutter

- Следуем [Effective Dart](https://dart.dev/effective-dart).
- Линтер: `flutter_lints` (включён через `analysis_options.yaml`).
- Форматирование: `dart format`.
- Sealed classes для state и error (вместо enum).
- Не используем `print()` (есть `debugPrint` если очень нужно).

### Backend (Node.js)

- CommonJS (`require`).
- ESLint стандартные правила (если настроите).
- Все async-функции возвращают `Promise`.
- Тесты на Jest.

## Структура feature

Каждая фича в `lib/features/<name>/`:
- `data/` — репозитории, data sources.
- `domain/` — модели, sealed states.
- `presentation/` — провайдеры, экраны.

Новый provider:
```dart
final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(...),
);
```

Новая модель — в `domain/`, сериализация через `toJson`/`fromJson`.

## Тесты

- Unit тесты для логики (validators, providers, services).
- Widget тесты для экранов (минимальные).
- Mock `SharedPreferences` через `SharedPreferences.setMockInitialValues({})`.
- Mock platform channels через `TestDefaultBinaryMessengerBinding`.

## Локализация

- Все строки — в `lib/l10n/app_*.arb`.
- Helper `S.of(context)` в `lib/core/utils/strings.dart` — fallback на русский.
- Новый ключ: добавить в `app_en.arb` и `app_ru.arb` + в `AppLocalizations._localizedValues`.

## Что НЕ делать

- ❌ Не добавлять логин в Instagram / cookies / авторизацию.
- ❌ Не обходить антибот-защиту.
- ❌ Не скачивать приватный контент.
- ❌ Не использовать сторонние сервисы для парсинга Instagram.
- ❌ Не добавлять рекламу и трекеры.

## Что делать

- ✅ Добавлять поддержку других публичных платформ (YouTube Shorts, TikTok).
- ✅ Улучшать UX (анимации, accessibility).
- ✅ Оптимизировать производительность.
- ✅ Писать тесты.
- ✅ Добавлять новые языки.
- ✅ Документировать архитектурные решения.

## Коммит-сообщения

Conventional Commits:
- `feat:` — новая фича.
- `fix:` — баг-фикс.
- `chore:` — рефактор, обновление зависимостей.
- `docs:` — документация.
- `test:` — тесты.
- `ci:` — CI/CD.

Пример:
```
feat(history): add search and swipe-to-delete
```

## Версионирование

Semantic Versioning: `MAJOR.MINOR.PATCH`.
- `MAJOR` — breaking changes.
- `MINOR` — новая фича (обратно совместимая).
- `PATCH` — баг-фикс.

Текущая версия: см. `CHANGELOG.md`.
