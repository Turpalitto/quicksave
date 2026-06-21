// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'QuickSave';

  @override
  String get homeHeroTitle => 'Сохраняйте медиа Instagram';

  @override
  String get homeHeroSubtitle => 'Отправьте ссылку из Instagram в QuickSave';

  @override
  String get urlFieldHint => 'Пост, reel, story или @профиль';

  @override
  String get urlFieldPaste => 'Вставить';

  @override
  String get downloadButton => 'Скачать';

  @override
  String get homeTip =>
      'Поделитесь из Instagram, вставьте ссылку или введите @username для сетки постов профиля.';

  @override
  String get homeClipboardDetected =>
      'В буфере обмена найдена ссылка Instagram';

  @override
  String homeFooter(String version) {
    return 'Только публичные посты • v$version';
  }

  @override
  String get errorEnterUrl => 'Введите ссылку.';

  @override
  String get errorInvalidUrl =>
      'Ссылка должна вести на публичный пост, story, highlights или профиль Instagram.';

  @override
  String get errorNotRecognized => 'Не удалось распознать ссылку Instagram.';

  @override
  String get previewTitle => 'Предпросмотр';

  @override
  String get previewResolving => 'Получаем информацию о видео…';

  @override
  String previewSource(String source) {
    return 'Источник: $source';
  }

  @override
  String get previewDownload => 'Скачать';

  @override
  String get previewCancel => 'Отмена';

  @override
  String previewDownloading(String percent) {
    return 'Скачиваем… $percent';
  }

  @override
  String get previewStop => 'Отмена';

  @override
  String get previewSuccess => 'Готово!';

  @override
  String get previewSavedTo => 'Сохранено в QuickSave';

  @override
  String get previewOpen => 'Открыть видео';

  @override
  String get previewShare => 'Поделиться';

  @override
  String previewDownloadSelected(int count) {
    return 'Скачать выбранные ($count)';
  }

  @override
  String previewTypeCarousel(int count) {
    return 'Карусель · $count файлов';
  }

  @override
  String get previewTypeStory => 'Story';

  @override
  String previewTypeHighlight(int count) {
    return 'Highlights · $count';
  }

  @override
  String get previewTypeSingle => 'Один пост';

  @override
  String get previewSelectAll => 'Выбрать все';

  @override
  String get previewDeselectAll => 'Снять выбор';

  @override
  String get previewVideosOnly => 'Только видео';

  @override
  String previewBatchProgress(int current, int total) {
    return 'Скачиваем $current из $total…';
  }

  @override
  String previewBatchSaved(String count) {
    return 'Сохранено файлов: $count';
  }

  @override
  String previewBatchSavedCount(int count) {
    return 'Сохранено $count файлов в QuickSave';
  }

  @override
  String previewPartialSuccess(int saved, int total, int failed) {
    return 'Сохранено $saved из $total ($failed с ошибкой)';
  }

  @override
  String previewTypeProfile(int count) {
    return 'Профиль · $count постов';
  }

  @override
  String get previewShareAll => 'Поделиться всеми';

  @override
  String get previewGoHome => 'На главную';

  @override
  String get previewLoadMore => 'Загрузить ещё';

  @override
  String get previewTapToPreview => 'Нажмите для просмотра';

  @override
  String get previewQualityTitle => 'Выберите качество';

  @override
  String get recentLinksTitle => 'Недавние ссылки';

  @override
  String get errorNoInternet => 'Нет подключения к интернету. Проверьте сеть.';

  @override
  String get errorPrivatePost =>
      'Пост приватный или требует входа в Instagram.';

  @override
  String get errorNotFoundPost => 'Пост не найден. Проверьте ссылку.';

  @override
  String get errorResolverFailed =>
      'Не удалось получить прямую ссылку. Попробуйте другой публичный пост.';

  @override
  String get errorServer => 'Ошибка сервера. Попробуйте позже.';

  @override
  String get errorNoSpace => 'Недостаточно места на устройстве.';

  @override
  String get errorFileWrite => 'Не удалось сохранить файл.';

  @override
  String get errorCancelled => 'Скачивание отменено.';

  @override
  String get errorUnknown => 'Неизвестная ошибка.';

  @override
  String get errorRetry => 'Повторить';

  @override
  String errorOpenFailed(String message) {
    return 'Не удалось открыть: $message';
  }

  @override
  String get errorFileMissing => 'Файл не найден.';

  @override
  String get historyTitle => 'История';

  @override
  String get historyEmpty => 'История пуста';

  @override
  String get historyEmptySubtitle => 'Скачанные файлы появятся здесь.';

  @override
  String get historySearchHint => 'Поиск по автору или ссылке';

  @override
  String get historySearchEmpty => 'Ничего не найдено по запросу.';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterVideo => 'Видео';

  @override
  String get historyFilterImage => 'Фото';

  @override
  String get historyFilterStories => 'Stories';

  @override
  String get historyFilterProfiles => 'Профили';

  @override
  String get historyDeleteFileTitle => 'Удалить файл?';

  @override
  String get historyDeleteFileBody => 'Удалить файл с устройства и из истории.';

  @override
  String get historyDeleteFileConfirm => 'Удалить файл';

  @override
  String get historyDeleteRecordBody => 'Удалить эту запись из истории?';

  @override
  String historyBatchFiles(int count) {
    return '$count файлов';
  }

  @override
  String get historyClearAll => 'Очистить всё';

  @override
  String get historyClearConfirmTitle => 'Очистить историю?';

  @override
  String get historyClearConfirmBody =>
      'Записи будут удалены. Файлы останутся.';

  @override
  String get historyClearConfirmYes => 'Очистить';

  @override
  String get historyClearConfirmNo => 'Отмена';

  @override
  String get historyFileUnavailable => 'файл недоступен';

  @override
  String get historyActionOpen => 'Открыть';

  @override
  String get historyActionShare => 'Поделиться';

  @override
  String get historyActionDelete => 'Удалить';

  @override
  String get historyDeleted => 'Удалено из истории.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionBehavior => 'Поведение';

  @override
  String get settingsAutoDownload => 'Автоскачивание после Share';

  @override
  String get settingsAutoDownloadSubtitle =>
      'Начинать загрузку сразу при получении ссылки из Instagram.';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsSubtitle =>
      'Показывать уведомление о завершении загрузки.';

  @override
  String get settingsSaveHistory => 'Сохранять историю';

  @override
  String get settingsSaveHistorySubtitle =>
      'Добавлять загруженные видео в список истории.';

  @override
  String get settingsSectionAppearance => 'Внешний вид';

  @override
  String get settingsThemeSystem => 'Системная';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsSectionBackend => 'Сервер';

  @override
  String get settingsBackendUrlLabel => 'Адрес сервера';

  @override
  String get settingsBackendUrlHint => 'http://10.0.2.2:3000';

  @override
  String get settingsBackendSave => 'Сохранить';

  @override
  String get settingsBackendSaved => 'Сохранено.';

  @override
  String get settingsBackendTest => 'Проверить связь';

  @override
  String get settingsBackendOnline => 'Backend доступен.';

  @override
  String get settingsBackendOffline =>
      'Не удалось подключиться к backend. Проверьте URL и сеть.';

  @override
  String get settingsBackendNote =>
      'Для эмулятора: http://10.0.2.2:3000.\nДля реального устройства: http://ВАШ-IP:3000.';

  @override
  String get settingsSectionData => 'Данные';

  @override
  String get settingsClearHistory => 'Очистить историю';

  @override
  String get settingsClearHistorySubtitle =>
      'Удалить все записи. Файлы останутся.';

  @override
  String get settingsCleared => 'История очищена.';

  @override
  String get settingsWatchClipboard => 'Следить за буфером';

  @override
  String get settingsWatchClipboardSubtitle =>
      'Предлагать ссылки Instagram при копировании.';

  @override
  String get settingsSaveInAuthorFolder => 'Папка по автору';

  @override
  String get settingsSaveInAuthorFolderSubtitle =>
      'Сохранять в подпапку @author внутри QuickSave.';

  @override
  String get settingsSaveToGallery => 'Сохранять в Gallery';

  @override
  String get settingsSaveToGallerySubtitle =>
      'Копировать в Pictures/Movies — файлы видны в галерее.';

  @override
  String get settingsBackendModeHosted => 'QuickSave Cloud (рекомендуется)';

  @override
  String get settingsBackendModeSelf => 'Свой сервер';

  @override
  String get settingsSectionPro => 'QuickSave Pro';

  @override
  String get settingsProActive => 'Pro активен';

  @override
  String get settingsProInactive => 'Планировщик, ZIP, свой сервер';

  @override
  String get settingsProLicenseHint => 'Ключ QS-PRO-XXXX';

  @override
  String get settingsProActivate => 'Активировать';

  @override
  String get settingsProActivated => 'Pro активирован!';

  @override
  String get settingsProInvalidKey => 'Неверный ключ';

  @override
  String get settingsSchedulerTitle => 'Планировщик профилей';

  @override
  String get settingsSchedulerSubtitle =>
      'Ежедневно проверять @профили на новые посты (Pro)';

  @override
  String get settingsSchedulerAddHint => '@username';

  @override
  String get settingsExportZip => 'Экспорт batch в ZIP';

  @override
  String get settingsPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get onboardingTitle => 'Начало работы';

  @override
  String get onboardingShareTitle => 'Поделиться из Instagram';

  @override
  String get onboardingShareBody =>
      'Публичный пост → Поделиться → QuickSave. С автоскачиванием файлы сохраняются в фоне.';

  @override
  String get onboardingTileTitle => 'Плитка в шторке';

  @override
  String get onboardingTileBody =>
      'Добавьте плитку QuickSave в быстрые настройки для вставки из буфера.';

  @override
  String get onboardingGalleryTitle => 'Сохранение в Gallery';

  @override
  String get onboardingGalleryBody =>
      'Включите «Сохранять в Gallery» в настройках — медиа появится в галерее.';

  @override
  String get onboardingGotIt => 'Понятно';

  @override
  String get privacyTitle => 'Политика конфиденциальности';

  @override
  String get privacyIntro => 'QuickSave уважает вашу приватность.';

  @override
  String get privacyBody =>
      'QuickSave не требует аккаунта Instagram. Обрабатываются только ссылки, которые вы сами отправили. Медиа хранится на устройстве. В режиме QuickSave Cloud URL отправляется на наш resolver для получения публичных ссылок — мы не храним ваши файлы на сервере. Self-hosted — URL только на ваш сервер. Контакт: support@quicksave.app';

  @override
  String get historyCopyCaption => 'Копировать описание';

  @override
  String get historyCaptionCopied => 'Описание скопировано';

  @override
  String get historyPostDate => 'Дата поста';

  @override
  String get historyExportZip => 'Экспорт ZIP';

  @override
  String get historyFailedBadge => 'Ошибка';

  @override
  String get historyRetryDownload => 'Повторить загрузку';

  @override
  String get historyRetryStarted => 'Повтор запущен…';

  @override
  String get historyRetryFailed => 'Повтор не удался';

  @override
  String get historyAddToCollection => 'В коллекцию';

  @override
  String get historyCreateCollection => 'Новая коллекция';

  @override
  String get historyCollectionNameHint => 'Название коллекции';

  @override
  String get historyCollectionCreated => 'Коллекция создана';

  @override
  String get historyAddedToCollection => 'Добавлено в коллекцию';

  @override
  String get historyCollectionAll => 'Все коллекции';

  @override
  String get queuePanelTitle => 'Очередь загрузок';

  @override
  String get queueStatusQueued => 'В очереди';

  @override
  String get queueStatusRunning => 'Скачивается';

  @override
  String get queueStatusPaused => 'Пауза';

  @override
  String get queueStatusFailed => 'Ошибка';

  @override
  String get queueStatusCompleted => 'Готово';

  @override
  String get queueStatusCancelled => 'Отменено';

  @override
  String get queuePause => 'Пауза';

  @override
  String get queueResume => 'Продолжить';

  @override
  String get queueCancel => 'Отмена';

  @override
  String get queueRetry => 'Повтор';

  @override
  String get semHomeDownload => 'Скачать по ссылке';

  @override
  String get semHomeHistory => 'Открыть историю';

  @override
  String get semHomeSettings => 'Открыть настройки';

  @override
  String get semHistorySearch => 'Поиск в библиотеке';

  @override
  String get semPreviewDownload => 'Скачать медиа';

  @override
  String get semPreviewCancel => 'Отменить предпросмотр';

  @override
  String get semPreviewStop => 'Остановить загрузку';

  @override
  String get semSettingsProActivate => 'Активировать Pro лицензию';

  @override
  String get semSettingsSchedulerAdd => 'Добавить профиль в расписание';

  @override
  String get notificationDownloadCompleteTitle => 'Файл сохранён';

  @override
  String get notificationChannelDownloads => 'Загрузки';

  @override
  String get notificationChannelDownloadsDesc =>
      'Уведомления о завершении скачивания';

  @override
  String notificationDownloadCompleteBody(String author) {
    return 'Автор: $author';
  }

  @override
  String get notificationDownloadCompleteBodyFallback =>
      'Файл сохранён в QuickSave';

  @override
  String get notificationDownloadErrorTitle => 'Ошибка загрузки';

  @override
  String get notificationDownloadAuthorPrefix => 'Автор';

  @override
  String get shareText => 'Видео из QuickSave';
}
