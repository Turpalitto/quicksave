# QuickSave

Android-приложение для сохранения **публичных** фото и видео из Instagram: Share Intent, профили, карусели, stories, Gallery, batch-download.

> QuickSave работает **только с публичным контентом**, который пользователь сам передал через Share или вставил вручную. Без логина, без обхода антибот-защиты.

> **Требования:** Android 11 (API 30)+, target Android 16 (API 36).

---

## Возможности

| Категория | Функции |
| --- | --- |
| Ввод | Share Intent, Quick Settings tile, clipboard, @username / URL |
| Контент | Посты, Reels, карусели, stories, highlights, профили + pagination |
| Скачивание | Прогресс, HTTP Range resume, foreground service, уведомления |
| Хранение | App folder + опционально Gallery (MediaStore) |
| UX | Material 3, RU/EN, onboarding, home widget |
| Pro | Scheduler UI, ZIP export, self-hosted backend, demo key `QS-PRO-DEMO1` |
| Backend | Hosted zero-config или свой сервер; Redis cache, metrics |

---

## Быстрый старт

### Backend (локально)

```bash
cd backend
npm install
npm start    # http://localhost:3000
npm test     # 105 tests
```

Production deploy: см. [`backend/render.yaml`](backend/render.yaml) и [`store/RELEASE_CHECKLIST.md`](store/RELEASE_CHECKLIST.md).

### Flutter

```bash
flutter pub get
flutter run
flutter test      # 106 tests
flutter analyze
cd backend && npm test   # 105 tests
```

### Release AAB (Google Play)

1. Keystore: [`android/key.properties.example`](android/key.properties.example)
2. `flutter build appbundle --release`

---

## Backend URL

| Режим | Где настроить |
| --- | --- |
| **Hosted** (по умолчанию) | `AppConstants.hostedBackendUrl` — после деплоя замените на ваш URL |
| **Self-hosted** (Pro) | Settings → Backend → Self-hosted → URL |

| Среда | URL |
| --- | --- |
| Эмулятор | `http://10.0.2.2:3000` |
| LAN | `http://<IP>:3000` |

---

## Структура

```
quicksave/
├── lib/                    # Flutter app
├── android/                # Kotlin: MainActivity, Gallery, Widget, QS tile, FG service
├── backend/                # Express resolver + Docker + render.yaml
├── store/                  # Play listing, privacy policy, release checklist
├── test/                   # Flutter tests
└── .github/workflows/      # CI
```

---

## Тестирование

```bash
flutter test && flutter analyze
cd backend && npm test
```

---

## Документация

| Файл | Описание |
| --- | --- |
| [CHANGELOG.md](CHANGELOG.md) | История версий |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Архитектура |
| [backend/README.md](backend/README.md) | API resolver |
| [store/RELEASE_CHECKLIST.md](store/RELEASE_CHECKLIST.md) | Чеклист публикации в Play |
| [store/privacy_policy.md](store/privacy_policy.md) | Privacy policy |

---

## Использование

Скачивайте только контент, на который у вас есть право. Уважайте авторские права и условия Instagram.
