import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Удобная обёртка над [AppLocalizations].
///
/// Использование: `Strings.of(context).xxx` или через `S.xxx(context)`.
///
/// Если контекст не имеет локализации (например, в тестах без MaterialApp),
/// возвращает null — вызывающий код должен это обработать.
class Strings {
  Strings._(this._l);

  final AppLocalizations? _l;

  /// Получить локализацию из контекста. Может вернуть null в тестах.
  static Strings of(BuildContext context) {
    try {
      return Strings._(AppLocalizations.of(context));
    } catch (_) {
      return Strings._(null);
    }
  }

  String _s(String Function(AppLocalizations) getter, String fallback) {
    final l = _l;
    if (l == null) return fallback;
    try {
      return getter(l);
    } catch (_) {
      return fallback;
    }
  }

  // ===== Home =====
  String get appTitle => _s((l) => l.appTitle, 'QuickSave');
  String get homeHeroTitle =>
      _s((l) => l.homeHeroTitle, 'Сохраняйте медиа Instagram');
  String get homeHeroSubtitle => _s(
    (l) => l.homeHeroSubtitle,
    'Поделитесь ссылкой из Instagram в QuickSave',
  );
  String get urlFieldHint =>
      _s((l) => l.urlFieldHint, 'Пост, reel, story или @профиль');
  String get urlFieldPaste => _s((l) => l.urlFieldPaste, 'Вставить');
  String get downloadButton => _s((l) => l.downloadButton, 'Скачать');
  String get homeTip => _s(
    (l) => l.homeTip,
    'Поделитесь из Instagram, вставьте ссылку или введите @username '
    'для сетки постов профиля.',
  );
  String homeFooter(String v) =>
      _s((l) => l.homeFooter(v), 'Только публичные посты • v$v');

  // ===== Errors =====
  String get homeClipboardDetected => _s(
    (l) => l.homeClipboardDetected,
    'В буфере обмена найдена ссылка Instagram',
  );
  String get errorEnterUrl => _s((l) => l.errorEnterUrl, 'Введите ссылку.');
  String get errorInvalidUrl => _s(
    (l) => l.errorInvalidUrl,
    'Ссылка должна вести на публичный пост Instagram '
    '(instagram.com/reel/, /p/, /tv/).',
  );
  String get errorNotRecognized => _s(
    (l) => l.errorNotRecognized,
    'Не удалось распознать ссылку Instagram.',
  );

  // ===== Preview =====
  String get previewTitle => _s((l) => l.previewTitle, 'Предпросмотр');
  String get previewResolving =>
      _s((l) => l.previewResolving, 'Получаем информацию о видео…');
  String previewResolvingAttempt(int attempt, int maxAttempts) => _s(
    (l) => l.previewResolvingAttempt(attempt, maxAttempts),
    'Подключение к серверу… попытка $attempt из $maxAttempts',
  );
  String previewSource(String url) =>
      _s((l) => l.previewSource(url), 'Источник: $url');
  String get previewDownload => _s((l) => l.previewDownload, 'Скачать');
  String get previewCancel => _s((l) => l.previewCancel, 'Отмена');
  String previewDownloading(String percent) =>
      _s((l) => l.previewDownloading(percent), 'Скачиваем… $percent');
  String get previewStop => _s((l) => l.previewStop, 'Отменить');
  String get previewSuccess => _s((l) => l.previewSuccess, 'Готово!');
  String get previewSavedTo =>
      _s((l) => l.previewSavedTo, 'Сохранено в QuickSave');
  String get previewOpen => _s((l) => l.previewOpen, 'Открыть видео');
  String get previewShare => _s((l) => l.previewShare, 'Поделиться');
  String previewDownloadSelected(int count) =>
      _s((l) => l.previewDownloadSelected(count), 'Скачать выбранные ($count)');
  String previewTypeCarousel(int count) =>
      _s((l) => l.previewTypeCarousel(count), 'Карусель · $count файлов');
  String get previewTypeStory => _s((l) => l.previewTypeStory, 'Story');
  String previewTypeHighlight(int count) =>
      _s((l) => l.previewTypeHighlight(count), 'Highlights · $count');
  String previewTypeProfile(int count) =>
      _s((l) => l.previewTypeProfile(count), 'Профиль · $count постов');
  String get previewTypeSingle => _s((l) => l.previewTypeSingle, 'Один пост');
  String get previewSelectAll => _s((l) => l.previewSelectAll, 'Выбрать все');
  String get previewDeselectAll =>
      _s((l) => l.previewDeselectAll, 'Снять выбор');
  String get previewVideosOnly =>
      _s((l) => l.previewVideosOnly, 'Только видео');
  String previewBatchProgress(int current, int total) => _s(
    (l) => l.previewBatchProgress(current, total),
    'Скачиваем $current из $total…',
  );
  String previewBatchSaved(String count) =>
      _s((l) => l.previewBatchSaved(count), 'Сохранено файлов: $count');
  String previewBatchSavedCount(int count) => _s(
    (l) => l.previewBatchSavedCount(count),
    'Сохранено $count файлов в QuickSave',
  );
  String previewPartialSuccess(int saved, int total, int failed) => _s(
    (l) => l.previewPartialSuccess(saved, total, failed),
    'Сохранено $saved из $total ($failed с ошибкой)',
  );
  String get previewShareAll =>
      _s((l) => l.previewShareAll, 'Поделиться всеми');
  String get previewGoHome => _s((l) => l.previewGoHome, 'На главную');
  String get previewLoadMore => _s((l) => l.previewLoadMore, 'Загрузить ещё');
  String get previewTapToPreview =>
      _s((l) => l.previewTapToPreview, 'Нажмите для просмотра');
  String get previewQualityTitle =>
      _s((l) => l.previewQualityTitle, 'Выберите качество');
  String get recentLinksTitle =>
      _s((l) => l.recentLinksTitle, 'Недавние ссылки');

  // ===== Error screens =====
  String get errorNoInternet => _s(
    (l) => l.errorNoInternet,
    'Нет подключения к интернету. Проверьте сеть.',
  );
  String get errorPrivatePost => _s(
    (l) => l.errorPrivatePost,
    'Пост приватный или требует входа в Instagram.',
  );
  String get errorNotFoundPost =>
      _s((l) => l.errorNotFoundPost, 'Пост не найден. Проверьте ссылку.');
  String get errorResolverFailed => _s(
    (l) => l.errorResolverFailed,
    'Не удалось получить прямую ссылку. '
    'Попробуйте другой публичный пост.',
  );
  String get errorServer =>
      _s((l) => l.errorServer, 'Ошибка сервера. Попробуйте позже.');
  String get errorNoSpace =>
      _s((l) => l.errorNoSpace, 'Недостаточно места на устройстве.');
  String get errorFileWrite =>
      _s((l) => l.errorFileWrite, 'Не удалось сохранить файл.');
  String get errorCancelled =>
      _s((l) => l.errorCancelled, 'Скачивание отменено.');
  String get errorUnknown => _s((l) => l.errorUnknown, 'Неизвестная ошибка.');
  String get errorRetry => _s((l) => l.errorRetry, 'Повторить');
  String errorOpenFailed(String message) =>
      _s((l) => l.errorOpenFailed(message), 'Не удалось открыть: $message');
  String get errorFileMissing =>
      _s((l) => l.errorFileMissing, 'Файл не найден.');

  // ===== History =====
  String get historyTitle => _s((l) => l.historyTitle, 'История');
  String get historyEmpty => _s((l) => l.historyEmpty, 'История пуста');
  String get historyEmptySubtitle =>
      _s((l) => l.historyEmptySubtitle, 'Скачанные файлы появятся здесь.');
  String get historySearchHint =>
      _s((l) => l.historySearchHint, 'Поиск по автору или ссылке');
  String get historySearchEmpty =>
      _s((l) => l.historySearchEmpty, 'Ничего не найдено по запросу.');
  String get historyFilterAll => _s((l) => l.historyFilterAll, 'Все');
  String get historyFilterVideo => _s((l) => l.historyFilterVideo, 'Видео');
  String get historyFilterImage => _s((l) => l.historyFilterImage, 'Фото');
  String get historyFilterStories =>
      _s((l) => l.historyFilterStories, 'Stories');
  String get historyFilterProfiles =>
      _s((l) => l.historyFilterProfiles, 'Профили');
  String get historyFilterReels => _s((l) => l.historyFilterReels, 'Reels');
  String get historyFilterCarousels =>
      _s((l) => l.historyFilterCarousels, 'Карусели');
  String get historyFilterErrors => _s((l) => l.historyFilterErrors, 'Ошибки');
  String get historyFilterRecent =>
      _s((l) => l.historyFilterRecent, 'Недавние');
  String get historyFilterUncollected =>
      _s((l) => l.historyFilterUncollected, 'Без коллекции');
  String get historyAlreadySaved =>
      _s((l) => l.historyAlreadySaved, 'Уже сохранено');
  String get historyMissingFile =>
      _s((l) => l.historyMissingFile, 'Файл не найден');
  String get historyBulkSelect => _s((l) => l.historyBulkSelect, 'Выбрать');
  String get historyBulkExportZip =>
      _s((l) => l.historyBulkExportZip, 'Экспорт ZIP');
  String get historyBulkDelete =>
      _s((l) => l.historyBulkDelete, 'Удалить выбранное');
  String get historyBulkCopyUrls =>
      _s((l) => l.historyBulkCopyUrls, 'Копировать URL');
  String get diagnosticsTitle => _s((l) => l.diagnosticsTitle, 'Диагностика');
  String get diagnosticsOpenSubtitle =>
      _s((l) => l.diagnosticsOpenSubtitle, 'Версия приложения, статус backend');
  String get diagnosticsAppVersion =>
      _s((l) => l.diagnosticsAppVersion, 'Версия приложения');
  String get diagnosticsBackendMode =>
      _s((l) => l.diagnosticsBackendMode, 'Режим backend');
  String get diagnosticsHostedStatus =>
      _s((l) => l.diagnosticsHostedStatus, 'Hosted backend');
  String get diagnosticsAvailable =>
      _s((l) => l.diagnosticsAvailable, 'Доступен');
  String get diagnosticsUnavailable =>
      _s((l) => l.diagnosticsUnavailable, 'Недоступен');
  String get diagnosticsLatency => _s((l) => l.diagnosticsLatency, 'Задержка');
  String get diagnosticsBackendVersion =>
      _s((l) => l.diagnosticsBackendVersion, 'Версия backend');
  String get diagnosticsPrivacyNote => _s(
    (l) => l.diagnosticsPrivacyNote,
    'Диагностика не включает ваши URL и файлы.',
  );
  String get diagnosticsCopy =>
      _s((l) => l.diagnosticsCopy, 'Копировать диагностику');
  String get diagnosticsCopied =>
      _s((l) => l.diagnosticsCopied, 'Диагностика скопирована');
  String get diagnosticsRefresh => _s((l) => l.diagnosticsRefresh, 'Обновить');
  String get diagnosticsError => _s((l) => l.diagnosticsError, 'Ошибка');
  String get diagnosticsAttempts => _s((l) => l.diagnosticsAttempts, 'Попыток');
  String get diagnosticsColdStartHint => _s(
    (l) => l.diagnosticsColdStartHint,
    'Hosted backend на free tier может «засыпать» — подождите до 60 секунд.',
  );
  String get watchlistTitle => _s((l) => l.watchlistTitle, 'Watchlist');
  String get watchlistOpenSubtitle =>
      _s((l) => l.watchlistOpenSubtitle, 'Публичные профили — редкие проверки');
  String get watchlistDisclaimer => _s(
    (l) => l.watchlistDisclaimer,
    'Только публичный контент. Частые проверки могут быть ограничены.',
  );
  String get watchlistEmpty =>
      _s((l) => l.watchlistEmpty, 'Добавьте профили в Настройки → Планировщик');
  String get watchlistFrequency => _s((l) => l.watchlistFrequency, 'Частота');
  String get watchlistLastChecked =>
      _s((l) => l.watchlistLastChecked, 'Последняя проверка');
  String get watchlistCheckNow =>
      _s((l) => l.watchlistCheckNow, 'Проверить сейчас');
  String get watchlistCheckQueued => _s(
    (l) => l.watchlistCheckQueued,
    'Ручная проверка — откройте приложение',
  );
  String get watchlistCheckFailed =>
      _s((l) => l.watchlistCheckFailed, 'Не удалось проверить профиль');
  String watchlistNoNewItems(int saved) => _s(
    (l) => l.watchlistNoNewItems(saved),
    'Нет новых постов ($saved уже в библиотеке)',
  );
  String get watchlistNewItemsTitle =>
      _s((l) => l.watchlistNewItemsTitle, 'Найдены новые посты');
  String watchlistNewItemsBody(int count, int saved) => _s(
    (l) => l.watchlistNewItemsBody(count, saved),
    '$count новых ($saved уже сохранены)',
  );
  String get watchlistOpenProfile =>
      _s((l) => l.watchlistOpenProfile, 'Открыть профиль');
  String watchlistNewItemsCount(int count) =>
      _s((l) => l.watchlistNewItemsCount(count), '$count новых при проверке');
  String get downloadStageAnalyzing =>
      _s((l) => l.downloadStageAnalyzing, 'Анализ ссылки…');
  String get downloadStageResolving =>
      _s((l) => l.downloadStageResolving, 'Получение медиа…');
  String get downloadStagePreparing =>
      _s((l) => l.downloadStagePreparing, 'Подготовка загрузки…');
  String get downloadStageDownloading =>
      _s((l) => l.downloadStageDownloading, 'Скачивание…');
  String get downloadStageSaving =>
      _s((l) => l.downloadStageSaving, 'Сохранение…');
  String get downloadStageAddedToLibrary =>
      _s((l) => l.downloadStageAddedToLibrary, 'Добавлено в библиотеку');
  String get postSaveSubtitle =>
      _s((l) => l.postSaveSubtitle, 'Сохранено в медиа-библиотеку');
  String get postSaveMore => _s((l) => l.postSaveMore, 'Сохранить ещё');
  String historyBulkSelected(int count) =>
      _s((l) => l.historyBulkSelected(count), 'Выбрано: $count');
  String get historyBulkUrlsCopied =>
      _s((l) => l.historyBulkUrlsCopied, 'URL скопированы');
  String get historySortSavedNewest =>
      _s((l) => l.historySortSavedNewest, 'Сначала новые');
  String get historySortSavedOldest =>
      _s((l) => l.historySortSavedOldest, 'Сначала старые');
  String get historySortUsername =>
      _s((l) => l.historySortUsername, 'По username');
  String get historySortType => _s((l) => l.historySortType, 'По типу');
  String get historySortSize => _s((l) => l.historySortSize, 'По размеру');
  String get historySortStatus => _s((l) => l.historySortStatus, 'По статусу');
  String get settingsFilenameTemplateTitle =>
      _s((l) => l.settingsFilenameTemplateTitle, 'Шаблон имени файла');
  String get settingsFilenameTemplateSubtitle => _s(
    (l) => l.settingsFilenameTemplateSubtitle,
    'Как называются файлы (Pro)',
  );
  String get settingsFilenamePresetDefault => _s(
    (l) => l.settingsFilenamePresetDefault,
    'username_type_shortcode_date',
  );
  String get settingsFilenamePresetDateFirst =>
      _s((l) => l.settingsFilenamePresetDateFirst, 'date_username_shortcode');
  String get settingsFilenamePresetFolder =>
      _s((l) => l.settingsFilenamePresetFolder, 'username/type/shortcode');
  String get settingsFilenamePresetCustom =>
      _s((l) => l.settingsFilenamePresetCustom, 'Свой шаблон');
  String get settingsFilenameTemplateCustomHint => _s(
    (l) => l.settingsFilenameTemplateCustomHint,
    '{username}_{type}_{shortcode}_{date}',
  );
  String get settingsFilenameTemplateTokens => _s(
    (l) => l.settingsFilenameTemplateTokens,
    'Токены: {username} {type} {shortcode} {date}',
  );
  String get settingsFilenameTemplatePreview =>
      _s((l) => l.settingsFilenameTemplatePreview, 'Превью');
  String get settingsCloudBackupTitle =>
      _s((l) => l.settingsCloudBackupTitle, 'Облачный бэкап');
  String get settingsCloudBackupSubtitle => _s(
    (l) => l.settingsCloudBackupSubtitle,
    'Загрузка ZIP-экспорта в ваше хранилище (Pro).',
  );
  String get settingsCloudBackupEnabled =>
      _s((l) => l.settingsCloudBackupEnabled, 'Бэкап после экспорта');
  String get settingsCloudBackupEnabledSubtitle => _s(
    (l) => l.settingsCloudBackupEnabledSubtitle,
    'При экспорте ZIP также загружать в облако',
  );
  String get settingsCloudBackupProvider =>
      _s((l) => l.settingsCloudBackupProvider, 'Назначение');
  String get settingsCloudBackupProviderNone =>
      _s((l) => l.settingsCloudBackupProviderNone, 'Нет');
  String get settingsCloudBackupProviderWebDav =>
      _s((l) => l.settingsCloudBackupProviderWebDav, 'WebDAV');
  String get settingsCloudBackupProviderS3 =>
      _s((l) => l.settingsCloudBackupProviderS3, 'S3');
  String get settingsCloudBackupProviderDrive =>
      _s((l) => l.settingsCloudBackupProviderDrive, 'Google Drive');
  String get settingsCloudBackupWebDavUrl =>
      _s((l) => l.settingsCloudBackupWebDavUrl, 'URL WebDAV');
  String get settingsCloudBackupWebDavUser =>
      _s((l) => l.settingsCloudBackupWebDavUser, 'Логин');
  String get settingsCloudBackupWebDavPassword =>
      _s((l) => l.settingsCloudBackupWebDavPassword, 'Пароль');
  String get settingsCloudBackupWebDavPath =>
      _s((l) => l.settingsCloudBackupWebDavPath, 'Папка');
  String get settingsCloudBackupS3Endpoint =>
      _s((l) => l.settingsCloudBackupS3Endpoint, 'Endpoint URL');
  String get settingsCloudBackupS3Bucket =>
      _s((l) => l.settingsCloudBackupS3Bucket, 'Bucket');
  String get settingsCloudBackupS3Region =>
      _s((l) => l.settingsCloudBackupS3Region, 'Регион');
  String get settingsCloudBackupS3Prefix =>
      _s((l) => l.settingsCloudBackupS3Prefix, 'Префикс');
  String get settingsCloudBackupS3AccessKey =>
      _s((l) => l.settingsCloudBackupS3AccessKey, 'Access key');
  String get settingsCloudBackupS3SecretKey =>
      _s((l) => l.settingsCloudBackupS3SecretKey, 'Secret key');
  String get settingsCloudBackupDriveNote =>
      _s((l) => l.settingsCloudBackupDriveNote, 'Google Drive — скоро.');
  String get settingsCloudBackupTest =>
      _s((l) => l.settingsCloudBackupTest, 'Проверить');
  String get settingsCloudBackupTestOk =>
      _s((l) => l.settingsCloudBackupTestOk, 'Подключение OK');
  String settingsCloudBackupTestFailed(String reason) =>
      _s((l) => l.settingsCloudBackupTestFailed(reason), 'Ошибка: $reason');
  String settingsCloudBackupComingSoon(String feature) =>
      _s((l) => l.settingsCloudBackupComingSoon(feature), '$feature — скоро');
  String get historyBulkCloudBackupOk =>
      _s((l) => l.historyBulkCloudBackupOk, 'Загружено в облако');
  String get historyBulkCloudBackupFailed =>
      _s((l) => l.historyBulkCloudBackupFailed, 'Ошибка облачного бэкапа');
  String get webDashboardTitle =>
      _s((l) => l.webDashboardTitle, 'QuickSave Web');
  String get webNavResolve => _s((l) => l.webNavResolve, 'Resolve');
  String get webNavLibrary => _s((l) => l.webNavLibrary, 'Библиотека');
  String get webNavSettings => _s((l) => l.webNavSettings, 'Настройки');
  String get webResolveTitle =>
      _s((l) => l.webResolveTitle, 'Resolve публичных ссылок');
  String get webResolveSubtitle => _s(
    (l) => l.webResolveSubtitle,
    'Вставьте URL — на web только предпросмотр.',
  );
  String get webResolveHint =>
      _s((l) => l.webResolveHint, 'Сохранение файлов — в Android-приложении.');
  String webResolveSuccess(int count) =>
      _s((l) => l.webResolveSuccess(count), 'Найдено: $count');
  String get webResolveMediaItem => _s((l) => l.webResolveMediaItem, 'Медиа');
  String get webOpenMedia => _s((l) => l.webOpenMedia, 'Открыть URL');
  String get webResolveMobileNote => _s(
    (l) => l.webResolveMobileNote,
    'Установите Android-приложение для сохранения.',
  );
  String get webLibraryTitle =>
      _s((l) => l.webLibraryTitle, 'Метаданные библиотеки');
  String get webLibrarySubtitle => _s(
    (l) => l.webLibrarySubtitle,
    'Импорт JSON из Android — локально в браузере.',
  );
  String get webLibrarySearchHint =>
      _s((l) => l.webLibrarySearchHint, 'Поиск…');
  String get webLibraryImportFile =>
      _s((l) => l.webLibraryImportFile, 'Импорт JSON');
  String get webLibraryExportCsv =>
      _s((l) => l.webLibraryExportCsv, 'Экспорт CSV');
  String get webLibraryClear => _s((l) => l.webLibraryClear, 'Очистить');
  String get webLibraryPasteJson =>
      _s((l) => l.webLibraryPasteJson, 'Вставить JSON');
  String get webLibraryPasteHint =>
      _s((l) => l.webLibraryPasteHint, 'metadata.json');
  String get webLibraryImport => _s((l) => l.webLibraryImport, 'Импорт');
  String webLibraryImported(int count) =>
      _s((l) => l.webLibraryImported(count), 'Импортировано: $count');
  String get webLibraryImportFailed =>
      _s((l) => l.webLibraryImportFailed, 'Неверный JSON');
  String get webLibraryEmpty =>
      _s((l) => l.webLibraryEmpty, 'Библиотека пуста');
  String get webSettingsTitle => _s((l) => l.webSettingsTitle, 'Backend');
  String get webSettingsSubtitle =>
      _s((l) => l.webSettingsSubtitle, 'Cloud или self-hosted resolver.');
  String get webSettingsCheckBackend =>
      _s((l) => l.webSettingsCheckBackend, 'Проверить');
  String get webSettingsBackendOk =>
      _s((l) => l.webSettingsBackendOk, 'Backend доступен');
  String get webSettingsBackendFail =>
      _s((l) => l.webSettingsBackendFail, 'Backend недоступен');
  String get webSettingsPrivacyNote => _s(
    (l) => l.webSettingsPrivacyNote,
    'Только URL, которые вы вставили, отправляются на resolver.',
  );
  String get historyDeleteFileTitle =>
      _s((l) => l.historyDeleteFileTitle, 'Удалить файл?');
  String get historyDeleteFileBody => _s(
    (l) => l.historyDeleteFileBody,
    'Удалить файл с устройства и из истории.',
  );
  String get historyDeleteFileConfirm =>
      _s((l) => l.historyDeleteFileConfirm, 'Удалить файл');
  String get historyDeleteRecordBody =>
      _s((l) => l.historyDeleteRecordBody, 'Удалить эту запись из истории?');
  String historyBatchFiles(int count) =>
      _s((l) => l.historyBatchFiles(count), '$count файлов');
  String get historyClearAll => _s((l) => l.historyClearAll, 'Очистить всё');
  String get historyClearConfirmTitle =>
      _s((l) => l.historyClearConfirmTitle, 'Очистить историю?');
  String get historyClearConfirmBody => _s(
    (l) => l.historyClearConfirmBody,
    'Все записи будут удалены. Файлы на устройстве останутся.',
  );
  String get historyClearConfirmYes =>
      _s((l) => l.historyClearConfirmYes, 'Очистить');
  String get historyClearConfirmNo =>
      _s((l) => l.historyClearConfirmNo, 'Отмена');
  String get historyFileUnavailable =>
      _s((l) => l.historyFileUnavailable, 'файл недоступен');
  String get historyActionOpen => _s((l) => l.historyActionOpen, 'Открыть');
  String get historyActionShare =>
      _s((l) => l.historyActionShare, 'Поделиться');
  String get historyActionDelete => _s((l) => l.historyActionDelete, 'Удалить');
  String get historyDeleted =>
      _s((l) => l.historyDeleted, 'Удалено из истории.');

  // ===== Settings =====
  String get settingsTitle => _s((l) => l.settingsTitle, 'Настройки');
  String get settingsSectionBehavior =>
      _s((l) => l.settingsSectionBehavior, 'Поведение');
  String get settingsAutoDownload =>
      _s((l) => l.settingsAutoDownload, 'Автоскачивание после Share');
  String get settingsAutoDownloadSubtitle => _s(
    (l) => l.settingsAutoDownloadSubtitle,
    'Сразу начинать загрузку, когда ссылка пришла из Instagram.',
  );
  String get settingsNotifications =>
      _s((l) => l.settingsNotifications, 'Уведомления');
  String get settingsNotificationsSubtitle => _s(
    (l) => l.settingsNotificationsSubtitle,
    'Показывать уведомление о завершении.',
  );
  String get settingsSaveHistory =>
      _s((l) => l.settingsSaveHistory, 'Сохранять историю');
  String get settingsSaveHistorySubtitle => _s(
    (l) => l.settingsSaveHistorySubtitle,
    'Добавлять скачанные файлы в список истории.',
  );
  String get settingsWatchClipboard =>
      _s((l) => l.settingsWatchClipboard, 'Следить за буфером');
  String get settingsWatchClipboardSubtitle => _s(
    (l) => l.settingsWatchClipboardSubtitle,
    'Предлагать ссылки Instagram при копировании.',
  );
  String get settingsSaveInAuthorFolder =>
      _s((l) => l.settingsSaveInAuthorFolder, 'Папка по автору');
  String get settingsSaveInAuthorFolderSubtitle => _s(
    (l) => l.settingsSaveInAuthorFolderSubtitle,
    'Сохранять в подпапку @author внутри QuickSave.',
  );
  String get settingsSaveToGallery =>
      _s((l) => l.settingsSaveToGallery, 'Сохранять в Gallery');
  String get settingsSaveToGallerySubtitle => _s(
    (l) => l.settingsSaveToGallerySubtitle,
    'Копировать в Pictures/Movies — файлы видны в галерее.',
  );
  String get settingsBackendModeHosted =>
      _s((l) => l.settingsBackendModeHosted, 'QuickSave Cloud (рекомендуется)');
  String get settingsBackendModeSelf =>
      _s((l) => l.settingsBackendModeSelf, 'Свой сервер');
  String get settingsSectionPro =>
      _s((l) => l.settingsSectionPro, 'QuickSave Pro');
  String get settingsProActive => _s((l) => l.settingsProActive, 'Pro активен');
  String get settingsProInactive =>
      _s((l) => l.settingsProInactive, 'Планировщик, ZIP, свой сервер');
  String get settingsProLicenseHint =>
      _s((l) => l.settingsProLicenseHint, 'Ключ QS-PRO-XXXX');
  String get settingsProActivate =>
      _s((l) => l.settingsProActivate, 'Активировать');
  String get settingsProActivated =>
      _s((l) => l.settingsProActivated, 'Pro активирован!');
  String get settingsProInvalidKey =>
      _s((l) => l.settingsProInvalidKey, 'Неверный ключ');
  String get settingsProSubscribe =>
      _s((l) => l.settingsProSubscribe, 'Подписка Google Play');
  String settingsProSubscribePrice(String price) =>
      _s((l) => l.settingsProSubscribePrice(price), 'Pro — $price');
  String get settingsProRestore =>
      _s((l) => l.settingsProRestore, 'Восстановить покупки');
  String get settingsProRestored =>
      _s((l) => l.settingsProRestored, 'Подписка восстановлена');
  String get settingsProRestoreEmpty =>
      _s((l) => l.settingsProRestoreEmpty, 'Активная подписка не найдена');
  String get settingsProBillingFailed =>
      _s((l) => l.settingsProBillingFailed, 'Не удалось начать покупку');
  String get settingsProBillingUnavailable =>
      _s((l) => l.settingsProBillingUnavailable, 'Google Play недоступен');
  String get settingsProLicenseDivider =>
      _s((l) => l.settingsProLicenseDivider, 'Или лицензионный ключ');
  String get settingsProActivePlay =>
      _s((l) => l.settingsProActivePlay, 'Pro через Google Play');
  String get settingsProActiveDemo =>
      _s((l) => l.settingsProActiveDemo, 'Pro demo');
  String settingsProActiveLicense(String hint) =>
      _s((l) => l.settingsProActiveLicense(hint), 'Pro ••••$hint');
  String get settingsProDemoBadge => _s((l) => l.settingsProDemoBadge, 'Demo');
  String get settingsSchedulerTitle =>
      _s((l) => l.settingsSchedulerTitle, 'Планировщик профилей');
  String get settingsSchedulerAddHint =>
      _s((l) => l.settingsSchedulerAddHint, '@username');
  String get settingsSchedulerSubtitle => _s(
    (l) => l.settingsSchedulerSubtitle,
    'Ежедневно проверять @профили на новые посты (Pro)',
  );
  String get settingsPrivacyPolicy =>
      _s((l) => l.settingsPrivacyPolicy, 'Политика конфиденциальности');
  String get onboardingTitle => _s((l) => l.onboardingTitle, 'Начало работы');
  String get onboardingShareTitle =>
      _s((l) => l.onboardingShareTitle, 'Поделиться из Instagram');
  String get onboardingShareBody => _s(
    (l) => l.onboardingShareBody,
    'Публичный пост → Поделиться → QuickSave.',
  );
  String get onboardingTileTitle =>
      _s((l) => l.onboardingTileTitle, 'Плитка в шторке');
  String get onboardingTileBody => _s(
    (l) => l.onboardingTileBody,
    'Добавьте плитку QuickSave в быстрые настройки.',
  );
  String get onboardingGalleryTitle =>
      _s((l) => l.onboardingGalleryTitle, 'Сохранение в Gallery');
  String get onboardingGalleryBody => _s(
    (l) => l.onboardingGalleryBody,
    'Включите «Сохранять в Gallery» в настройках.',
  );
  String get onboardingGotIt => _s((l) => l.onboardingGotIt, 'Понятно');
  String get privacyTitle =>
      _s((l) => l.privacyTitle, 'Политика конфиденциальности');
  String get privacyIntro =>
      _s((l) => l.privacyIntro, 'QuickSave уважает вашу приватность.');
  String get privacyBody => _s(
    (l) => l.privacyBody,
    'QuickSave не требует аккаунта Instagram. '
    'Обрабатываются только ссылки, которые вы сами отправили.',
  );
  String get historyCopyCaption =>
      _s((l) => l.historyCopyCaption, 'Копировать описание');
  String get historyCaptionCopied =>
      _s((l) => l.historyCaptionCopied, 'Описание скопировано');
  String get historyPostDate => _s((l) => l.historyPostDate, 'Дата поста');
  String get historyExportZip => _s((l) => l.historyExportZip, 'Экспорт ZIP');
  String get historyFailedBadge => _s((l) => l.historyFailedBadge, 'Ошибка');
  String get historyRetryDownload =>
      _s((l) => l.historyRetryDownload, 'Повторить загрузку');
  String get historyRetryStarted =>
      _s((l) => l.historyRetryStarted, 'Повтор запущен…');
  String get historyRetryFailed =>
      _s((l) => l.historyRetryFailed, 'Повтор не удался');
  String get historyAddToCollection =>
      _s((l) => l.historyAddToCollection, 'В коллекцию');
  String get historyCreateCollection =>
      _s((l) => l.historyCreateCollection, 'Новая коллекция');
  String get historyCollectionNameHint =>
      _s((l) => l.historyCollectionNameHint, 'Название коллекции');
  String get historyCollectionCreated =>
      _s((l) => l.historyCollectionCreated, 'Коллекция создана');
  String get historyAddedToCollection =>
      _s((l) => l.historyAddedToCollection, 'Добавлено в коллекцию');
  String get historyCollectionAll =>
      _s((l) => l.historyCollectionAll, 'Все коллекции');
  String get queuePanelTitle =>
      _s((l) => l.queuePanelTitle, 'Очередь загрузок');
  String get queueStatusQueued => _s((l) => l.queueStatusQueued, 'В очереди');
  String get queueStatusRunning =>
      _s((l) => l.queueStatusRunning, 'Скачивается');
  String get queueStatusPaused => _s((l) => l.queueStatusPaused, 'Пауза');
  String get queueStatusFailed => _s((l) => l.queueStatusFailed, 'Ошибка');
  String get queueStatusCompleted =>
      _s((l) => l.queueStatusCompleted, 'Готово');
  String get queueStatusCancelled =>
      _s((l) => l.queueStatusCancelled, 'Отменено');
  String get queuePause => _s((l) => l.queuePause, 'Пауза');
  String get queueResume => _s((l) => l.queueResume, 'Продолжить');
  String get queueCancel => _s((l) => l.queueCancel, 'Отмена');
  String get queueRetry => _s((l) => l.queueRetry, 'Повтор');
  String get semHomeDownload =>
      _s((l) => l.semHomeDownload, 'Скачать по ссылке');
  String get semHomeHistory => _s((l) => l.semHomeHistory, 'Открыть историю');
  String get semHomeSettings =>
      _s((l) => l.semHomeSettings, 'Открыть настройки');
  String get semHistorySearch =>
      _s((l) => l.semHistorySearch, 'Поиск в библиотеке');
  String get semPreviewDownload =>
      _s((l) => l.semPreviewDownload, 'Скачать медиа');
  String get semPreviewCancel =>
      _s((l) => l.semPreviewCancel, 'Отменить предпросмотр');
  String get semPreviewStop =>
      _s((l) => l.semPreviewStop, 'Остановить загрузку');
  String get semSettingsProActivate =>
      _s((l) => l.semSettingsProActivate, 'Активировать Pro лицензию');
  String get semSettingsSchedulerAdd =>
      _s((l) => l.semSettingsSchedulerAdd, 'Добавить профиль в расписание');
  String get settingsSectionAppearance =>
      _s((l) => l.settingsSectionAppearance, 'Внешний вид');
  String get settingsThemeSystem =>
      _s((l) => l.settingsThemeSystem, 'Как в системе');
  String get settingsThemeLight => _s((l) => l.settingsThemeLight, 'Светлая');
  String get settingsThemeDark => _s((l) => l.settingsThemeDark, 'Тёмная');
  String get settingsSectionBackend =>
      _s((l) => l.settingsSectionBackend, 'Backend');
  String get settingsBackendUrlLabel =>
      _s((l) => l.settingsBackendUrlLabel, 'Backend URL');
  String get settingsBackendUrlHint =>
      _s((l) => l.settingsBackendUrlHint, 'http://10.0.2.2:3000');
  String get settingsBackendSave =>
      _s((l) => l.settingsBackendSave, 'Сохранить');
  String get settingsBackendSaved =>
      _s((l) => l.settingsBackendSaved, 'Сохранено.');
  String get settingsBackendTest =>
      _s((l) => l.settingsBackendTest, 'Проверить связь');
  String get settingsBackendOnline =>
      _s((l) => l.settingsBackendOnline, 'Backend доступен.');
  String get settingsBackendOffline => _s(
    (l) => l.settingsBackendOffline,
    'Не удалось подключиться к backend. Проверьте URL и сеть.',
  );
  String get settingsBackendNote => _s(
    (l) => l.settingsBackendNote,
    'Для эмулятора Android используйте http://10.0.2.2:3000.\n'
    'Для реального устройства — http://IP-вашего-компьютера:3000.',
  );
  String get settingsSectionData => _s((l) => l.settingsSectionData, 'Данные');
  String get settingsClearHistory =>
      _s((l) => l.settingsClearHistory, 'Очистить историю');
  String get settingsClearHistorySubtitle => _s(
    (l) => l.settingsClearHistorySubtitle,
    'Удалить все записи. Файлы останутся.',
  );
  String get settingsCleared =>
      _s((l) => l.settingsCleared, 'История очищена.');

  // ===== Notifications =====
  String get notificationDownloadCompleteTitle =>
      _s((l) => l.notificationDownloadCompleteTitle, 'Видео сохранено');
  String notificationDownloadCompleteBody(String author) =>
      _s((l) => l.notificationDownloadCompleteBody(author), 'Автор: $author');
  String get notificationDownloadCompleteBodyFallback => _s(
    (l) => l.notificationDownloadCompleteBodyFallback,
    'Файл сохранён в QuickSave',
  );
  String get notificationDownloadErrorTitle =>
      _s((l) => l.notificationDownloadErrorTitle, 'Ошибка скачивания');
  // Префикс «Автор:» — нужен провайдеру для конкатенации.
  String get notificationDownloadAuthorPrefix =>
      _s((l) => l.notificationDownloadAuthorPrefix, 'Автор');
  String get notificationChannelDownloads =>
      _s((l) => l.notificationChannelDownloads, 'Загрузки');
  String get notificationChannelDownloadsDesc => _s(
    (l) => l.notificationChannelDownloadsDesc,
    'Уведомления о завершении скачивания',
  );

  // ===== Share =====
  String get shareText => _s((l) => l.shareText, 'Видео из QuickSave');
}

/// Удобный shortcut: `S.of(context)`.
class S {
  S._();
  static Strings of(BuildContext context) => Strings.of(context);
}
