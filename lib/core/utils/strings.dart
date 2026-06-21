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
      'Поделитесь ссылкой из Instagram в QuickSave');
  String get urlFieldHint =>
      _s((l) => l.urlFieldHint, 'Пост, reel, story или @профиль');
  String get urlFieldPaste => _s((l) => l.urlFieldPaste, 'Вставить');
  String get downloadButton =>
      _s((l) => l.downloadButton, 'Скачать');
  String get homeTip => _s(
      (l) => l.homeTip,
      'Поделитесь из Instagram, вставьте ссылку или введите @username '
          'для сетки постов профиля.');
  String homeFooter(String v) => _s(
      (l) => l.homeFooter(v), 'Только публичные посты • v$v');

  // ===== Errors =====
  String get homeClipboardDetected => _s(
      (l) => l.homeClipboardDetected,
      'В буфере обмена найдена ссылка Instagram');
  String get errorEnterUrl =>
      _s((l) => l.errorEnterUrl, 'Введите ссылку.');
  String get errorInvalidUrl => _s((l) => l.errorInvalidUrl,
      'Ссылка должна вести на публичный пост Instagram '
          '(instagram.com/reel/, /p/, /tv/).');
  String get errorNotRecognized => _s(
      (l) => l.errorNotRecognized, 'Не удалось распознать ссылку Instagram.');

  // ===== Preview =====
  String get previewTitle =>
      _s((l) => l.previewTitle, 'Предпросмотр');
  String get previewResolving => _s(
      (l) => l.previewResolving, 'Получаем информацию о видео…');
  String previewSource(String url) => _s(
      (l) => l.previewSource(url), 'Источник: $url');
  String get previewDownload =>
      _s((l) => l.previewDownload, 'Скачать');
  String get previewCancel =>
      _s((l) => l.previewCancel, 'Отмена');
  String previewDownloading(String percent) => _s(
      (l) => l.previewDownloading(percent), 'Скачиваем… $percent');
  String get previewStop =>
      _s((l) => l.previewStop, 'Отменить');
  String get previewSuccess => _s((l) => l.previewSuccess, 'Готово!');
  String get previewSavedTo => _s(
      (l) => l.previewSavedTo, 'Сохранено в QuickSave');
  String get previewOpen =>
      _s((l) => l.previewOpen, 'Открыть видео');
  String get previewShare =>
      _s((l) => l.previewShare, 'Поделиться');
  String previewDownloadSelected(int count) => _s(
      (l) => l.previewDownloadSelected(count), 'Скачать выбранные ($count)');
  String previewTypeCarousel(int count) => _s(
      (l) => l.previewTypeCarousel(count), 'Карусель · $count файлов');
  String get previewTypeStory =>
      _s((l) => l.previewTypeStory, 'Story');
  String previewTypeHighlight(int count) => _s(
      (l) => l.previewTypeHighlight(count), 'Highlights · $count');
  String previewTypeProfile(int count) => _s(
      (l) => l.previewTypeProfile(count), 'Профиль · $count постов');
  String get previewTypeSingle =>
      _s((l) => l.previewTypeSingle, 'Один пост');
  String get previewSelectAll =>
      _s((l) => l.previewSelectAll, 'Выбрать все');
  String get previewDeselectAll =>
      _s((l) => l.previewDeselectAll, 'Снять выбор');
  String get previewVideosOnly =>
      _s((l) => l.previewVideosOnly, 'Только видео');
  String previewBatchProgress(int current, int total) => _s(
      (l) => l.previewBatchProgress(current, total),
      'Скачиваем $current из $total…');
  String previewBatchSaved(String count) => _s(
      (l) => l.previewBatchSaved(count), 'Сохранено файлов: $count');
  String previewBatchSavedCount(int count) => _s(
      (l) => l.previewBatchSavedCount(count),
      'Сохранено $count файлов в QuickSave');
  String previewPartialSuccess(int saved, int total, int failed) => _s(
      (l) => l.previewPartialSuccess(saved, total, failed),
      'Сохранено $saved из $total ($failed с ошибкой)');
  String get previewShareAll =>
      _s((l) => l.previewShareAll, 'Поделиться всеми');
  String get previewGoHome =>
      _s((l) => l.previewGoHome, 'На главную');
  String get previewLoadMore =>
      _s((l) => l.previewLoadMore, 'Загрузить ещё');
  String get previewTapToPreview =>
      _s((l) => l.previewTapToPreview, 'Нажмите для просмотра');
  String get previewQualityTitle =>
      _s((l) => l.previewQualityTitle, 'Выберите качество');
  String get recentLinksTitle =>
      _s((l) => l.recentLinksTitle, 'Недавние ссылки');

  // ===== Error screens =====
  String get errorNoInternet => _s(
      (l) => l.errorNoInternet,
      'Нет подключения к интернету. Проверьте сеть.');
  String get errorPrivatePost => _s(
      (l) => l.errorPrivatePost,
      'Пост приватный или требует входа в Instagram.');
  String get errorNotFoundPost => _s(
      (l) => l.errorNotFoundPost, 'Пост не найден. Проверьте ссылку.');
  String get errorResolverFailed => _s(
      (l) => l.errorResolverFailed,
      'Не удалось получить прямую ссылку. '
          'Попробуйте другой публичный пост.');
  String get errorServer =>
      _s((l) => l.errorServer, 'Ошибка сервера. Попробуйте позже.');
  String get errorNoSpace => _s(
      (l) => l.errorNoSpace, 'Недостаточно места на устройстве.');
  String get errorFileWrite => _s(
      (l) => l.errorFileWrite, 'Не удалось сохранить файл.');
  String get errorCancelled => _s(
      (l) => l.errorCancelled, 'Скачивание отменено.');
  String get errorUnknown =>
      _s((l) => l.errorUnknown, 'Неизвестная ошибка.');
  String get errorRetry => _s((l) => l.errorRetry, 'Повторить');
  String errorOpenFailed(String message) => _s(
      (l) => l.errorOpenFailed(message), 'Не удалось открыть: $message');
  String get errorFileMissing =>
      _s((l) => l.errorFileMissing, 'Файл не найден.');

  // ===== History =====
  String get historyTitle => _s((l) => l.historyTitle, 'История');
  String get historyEmpty =>
      _s((l) => l.historyEmpty, 'История пуста');
  String get historyEmptySubtitle => _s(
      (l) => l.historyEmptySubtitle,
      'Скачанные файлы появятся здесь.');
  String get historySearchHint =>
      _s((l) => l.historySearchHint, 'Поиск по автору или ссылке');
  String get historySearchEmpty =>
      _s((l) => l.historySearchEmpty, 'Ничего не найдено по запросу.');
  String get historyFilterAll =>
      _s((l) => l.historyFilterAll, 'Все');
  String get historyFilterVideo =>
      _s((l) => l.historyFilterVideo, 'Видео');
  String get historyFilterImage =>
      _s((l) => l.historyFilterImage, 'Фото');
  String get historyDeleteFileTitle =>
      _s((l) => l.historyDeleteFileTitle, 'Удалить файл?');
  String get historyDeleteFileBody => _s(
      (l) => l.historyDeleteFileBody,
      'Удалить файл с устройства и из истории.');
  String get historyDeleteFileConfirm =>
      _s((l) => l.historyDeleteFileConfirm, 'Удалить файл');
  String get historyDeleteRecordBody => _s(
      (l) => l.historyDeleteRecordBody,
      'Удалить эту запись из истории?');
  String historyBatchFiles(int count) => _s(
      (l) => l.historyBatchFiles(count), '$count файлов');
  String get historyClearAll =>
      _s((l) => l.historyClearAll, 'Очистить всё');
  String get historyClearConfirmTitle => _s(
      (l) => l.historyClearConfirmTitle, 'Очистить историю?');
  String get historyClearConfirmBody => _s(
      (l) => l.historyClearConfirmBody,
      'Все записи будут удалены. Файлы на устройстве останутся.');
  String get historyClearConfirmYes =>
      _s((l) => l.historyClearConfirmYes, 'Очистить');
  String get historyClearConfirmNo =>
      _s((l) => l.historyClearConfirmNo, 'Отмена');
  String get historyFileUnavailable => _s(
      (l) => l.historyFileUnavailable, 'файл недоступен');
  String get historyActionOpen =>
      _s((l) => l.historyActionOpen, 'Открыть');
  String get historyActionShare =>
      _s((l) => l.historyActionShare, 'Поделиться');
  String get historyActionDelete =>
      _s((l) => l.historyActionDelete, 'Удалить');
  String get historyDeleted => _s(
      (l) => l.historyDeleted, 'Удалено из истории.');

  // ===== Settings =====
  String get settingsTitle =>
      _s((l) => l.settingsTitle, 'Настройки');
  String get settingsSectionBehavior =>
      _s((l) => l.settingsSectionBehavior, 'Поведение');
  String get settingsAutoDownload => _s(
      (l) => l.settingsAutoDownload, 'Автоскачивание после Share');
  String get settingsAutoDownloadSubtitle => _s(
      (l) => l.settingsAutoDownloadSubtitle,
      'Сразу начинать загрузку, когда ссылка пришла из Instagram.');
  String get settingsNotifications =>
      _s((l) => l.settingsNotifications, 'Уведомления');
  String get settingsNotificationsSubtitle => _s(
      (l) => l.settingsNotificationsSubtitle,
      'Показывать уведомление о завершении.');
  String get settingsSaveHistory => _s(
      (l) => l.settingsSaveHistory, 'Сохранять историю');
  String get settingsSaveHistorySubtitle => _s(
      (l) => l.settingsSaveHistorySubtitle,
      'Добавлять скачанные файлы в список истории.');
  String get settingsWatchClipboard => _s(
      (l) => l.settingsWatchClipboard, 'Следить за буфером');
  String get settingsWatchClipboardSubtitle => _s(
      (l) => l.settingsWatchClipboardSubtitle,
      'Предлагать ссылки Instagram при копировании.');
  String get settingsSaveInAuthorFolder => _s(
      (l) => l.settingsSaveInAuthorFolder, 'Папка по автору');
  String get settingsSaveInAuthorFolderSubtitle => _s(
      (l) => l.settingsSaveInAuthorFolderSubtitle,
      'Сохранять в подпапку @author внутри QuickSave.');
  String get settingsSaveToGallery => _s(
      (l) => l.settingsSaveToGallery, 'Сохранять в Gallery');
  String get settingsSaveToGallerySubtitle => _s(
      (l) => l.settingsSaveToGallerySubtitle,
      'Копировать в Pictures/Movies — файлы видны в галерее.');
  String get settingsBackendModeHosted => _s(
      (l) => l.settingsBackendModeHosted, 'QuickSave Cloud (рекомендуется)');
  String get settingsBackendModeSelf =>
      _s((l) => l.settingsBackendModeSelf, 'Свой сервер');
  String get settingsSectionPro =>
      _s((l) => l.settingsSectionPro, 'QuickSave Pro');
  String get settingsProActive =>
      _s((l) => l.settingsProActive, 'Pro активен');
  String get settingsProInactive => _s(
      (l) => l.settingsProInactive, 'Планировщик, ZIP, свой сервер');
  String get settingsProLicenseHint =>
      _s((l) => l.settingsProLicenseHint, 'Ключ QS-PRO-XXXX');
  String get settingsProActivate =>
      _s((l) => l.settingsProActivate, 'Активировать');
  String get settingsProActivated =>
      _s((l) => l.settingsProActivated, 'Pro активирован!');
  String get settingsProInvalidKey =>
      _s((l) => l.settingsProInvalidKey, 'Неверный ключ');
  String get settingsSchedulerTitle => _s(
      (l) => l.settingsSchedulerTitle, 'Планировщик профилей');
  String get settingsSchedulerAddHint =>
      _s((l) => l.settingsSchedulerAddHint, '@username');
  String get settingsSchedulerSubtitle => _s(
      (l) => l.settingsSchedulerSubtitle,
      'Ежедневно проверять @профили на новые посты (Pro)');
  String get settingsPrivacyPolicy =>
      _s((l) => l.settingsPrivacyPolicy, 'Политика конфиденциальности');
  String get onboardingTitle =>
      _s((l) => l.onboardingTitle, 'Начало работы');
  String get onboardingShareTitle =>
      _s((l) => l.onboardingShareTitle, 'Поделиться из Instagram');
  String get onboardingShareBody => _s(
      (l) => l.onboardingShareBody,
      'Публичный пост → Поделиться → QuickSave.');
  String get onboardingTileTitle =>
      _s((l) => l.onboardingTileTitle, 'Плитка в шторке');
  String get onboardingTileBody => _s(
      (l) => l.onboardingTileBody,
      'Добавьте плитку QuickSave в быстрые настройки.');
  String get onboardingGalleryTitle =>
      _s((l) => l.onboardingGalleryTitle, 'Сохранение в Gallery');
  String get onboardingGalleryBody => _s(
      (l) => l.onboardingGalleryBody,
      'Включите «Сохранять в Gallery» в настройках.');
  String get onboardingGotIt => _s((l) => l.onboardingGotIt, 'Понятно');
  String get privacyTitle =>
      _s((l) => l.privacyTitle, 'Политика конфиденциальности');
  String get privacyIntro =>
      _s((l) => l.privacyIntro, 'QuickSave уважает вашу приватность.');
  String get privacyBody => _s(
      (l) => l.privacyBody,
      'QuickSave не требует аккаунта Instagram. '
          'Обрабатываются только ссылки, которые вы сами отправили.');
  String get historyCopyCaption =>
      _s((l) => l.historyCopyCaption, 'Копировать описание');
  String get historyCaptionCopied =>
      _s((l) => l.historyCaptionCopied, 'Описание скопировано');
  String get historyPostDate =>
      _s((l) => l.historyPostDate, 'Дата поста');
  String get historyExportZip =>
      _s((l) => l.historyExportZip, 'Экспорт ZIP');
  String get settingsSectionAppearance => _s(
      (l) => l.settingsSectionAppearance, 'Внешний вид');
  String get settingsThemeSystem =>
      _s((l) => l.settingsThemeSystem, 'Как в системе');
  String get settingsThemeLight =>
      _s((l) => l.settingsThemeLight, 'Светлая');
  String get settingsThemeDark =>
      _s((l) => l.settingsThemeDark, 'Тёмная');
  String get settingsSectionBackend =>
      _s((l) => l.settingsSectionBackend, 'Backend');
  String get settingsBackendUrlLabel => _s(
      (l) => l.settingsBackendUrlLabel, 'Backend URL');
  String get settingsBackendUrlHint => _s(
      (l) => l.settingsBackendUrlHint, 'http://10.0.2.2:3000');
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
      'Не удалось подключиться к backend. Проверьте URL и сеть.');
  String get settingsBackendNote => _s(
      (l) => l.settingsBackendNote,
      'Для эмулятора Android используйте http://10.0.2.2:3000.\n'
          'Для реального устройства — http://IP-вашего-компьютера:3000.');
  String get settingsSectionData =>
      _s((l) => l.settingsSectionData, 'Данные');
  String get settingsClearHistory => _s(
      (l) => l.settingsClearHistory, 'Очистить историю');
  String get settingsClearHistorySubtitle => _s(
      (l) => l.settingsClearHistorySubtitle,
      'Удалить все записи. Файлы останутся.');
  String get settingsCleared =>
      _s((l) => l.settingsCleared, 'История очищена.');

  // ===== Notifications =====
  String get notificationDownloadCompleteTitle => _s(
      (l) => l.notificationDownloadCompleteTitle, 'Видео сохранено');
  String notificationDownloadCompleteBody(String author) => _s(
      (l) => l.notificationDownloadCompleteBody(author),
      'Автор: $author');
  String get notificationDownloadCompleteBodyFallback => _s(
      (l) => l.notificationDownloadCompleteBodyFallback,
      'Файл сохранён в QuickSave');
  String get notificationDownloadErrorTitle => _s(
      (l) => l.notificationDownloadErrorTitle, 'Ошибка скачивания');
  // Префикс «Автор:» — нужен провайдеру для конкатенации.
  String get notificationDownloadAuthorPrefix => _s(
      (l) => l.notificationDownloadAuthorPrefix, 'Автор');
  String get notificationChannelDownloads => _s(
      (l) => l.notificationChannelDownloads, 'Загрузки');
  String get notificationChannelDownloadsDesc => _s(
      (l) => l.notificationChannelDownloadsDesc,
      'Уведомления о завершении скачивания');

  // ===== Share =====
  String get shareText =>
      _s((l) => l.shareText, 'Видео из QuickSave');
}

/// Удобный shortcut: `S.of(context)`.
class S {
  S._();
  static Strings of(BuildContext context) => Strings.of(context);
}
