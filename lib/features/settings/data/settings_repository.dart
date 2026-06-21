import '../../../services/storage_service.dart';
import '../domain/app_settings.dart';

/// Репозиторий настроек.
class SettingsRepository {
  SettingsRepository._();
  static final SettingsRepository instance = SettingsRepository._();

  Future<AppSettings> get() => StorageService.instance.loadSettings();

  Future<void> save(AppSettings settings) =>
      StorageService.instance.saveSettings(settings);
}
