# Contributing to QuickSave

Thank you for helping improve QuickSave.

## Development setup

```bash
git clone https://github.com/Turpalitto/quicksave.git
cd quicksave
flutter pub get
flutter gen-l10n
cd backend && npm install
```

## Before opening a PR

```bash
dart format lib test
flutter analyze
flutter test
cd backend && npm test
```

## Architecture notes

- **Flutter** — feature folders under `lib/features/`
- **Backend resolver** — modular services under `backend/src/services/`
- **i18n** — ARB files + `flutter gen-l10n` (do not hand-edit generated localizations)
- **History** — stored in `quicksave.history.v2` with automatic v1 migration

## Commit style

- Imperative subject line (`Add download queue retry`)
- Reference issue when applicable

## Security

Do not commit keystore files, `.env`, or API secrets. Report vulnerabilities privately to support@quicksave.app.
