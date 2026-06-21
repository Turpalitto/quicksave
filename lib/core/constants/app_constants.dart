/// Константы приложения QuickSave.
class AppConstants {
  AppConstants._();

  static const String appName = 'QuickSave';

  /// Публичный hosted resolver (zero-config).
  /// После деплоя backend замените на ваш production URL.
  static const String hostedBackendUrl = 'https://quicksave-api.onrender.com';

  /// Self-hosted URL по умолчанию (эмулятор / локальная разработка).
  static const String defaultSelfHostedBackendUrl = 'http://10.0.2.2:3000';

  @Deprecated('Use AppSettings.effectiveBackendUrl')
  static const String defaultBackendUrl = defaultSelfHostedBackendUrl;

  /// Конечная точка resolver.
  static const String resolveEndpoint = '/resolve';

  /// Таймаут запросов к backend.
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Имя папки внутри публичного Downloads.
  static const String downloadsFolderName = 'QuickSave';

  /// Имя файла для логов (если понадобится).
  static const String historyPrefsKey = 'quicksave.history.v1';
  static const String historyV2PrefsKey = 'quicksave.history.v2';
  static const String collectionsPrefsKey = 'quicksave.collections.v1';
  static const String settingsPrefsKey = 'quicksave.settings.v1';

  /// Max single-file download size (500 MB).
  static const int maxDownloadBytes = 500 * 1024 * 1024;

  static const int downloadMaxRetries = 3;
  static const int downloadRetryBaseMs = 1000;

  /// Допустимые паттерны Instagram (публичных постов).
  static const List<String> instagramPatterns = [
    'instagram.com/reel/',
    'instagram.com/p/',
    'instagram.com/tv/',
    'instagram.com/video/reel/',
    'instagram.com/reels/',
    'instagr.am/reel/',
    'instagr.am/p/',
    'instagr.am/tv/',
  ];

  /// Канал для Share Intent из MainActivity (Kotlin).
  static const String shareChannelName = 'quicksave/share_intent';
  static const String shareChannelMethod = 'onSharedText';

  /// Канал для управления foreground-сервисом скачивания (Kotlin).
  static const String foregroundChannelName = 'quicksave/download_fg';

  /// Сохранение в Gallery через MediaStore (Kotlin).
  static const String galleryChannelName = 'quicksave/gallery';

  static const String onboardingPrefsKey = 'quicksave.onboarding.v1';
  static const String schedulerTaskName = 'quicksaveProfileSync';
  static const String proLicensePrefix = 'QS-PRO-';
}
