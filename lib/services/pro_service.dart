import '../core/constants/app_constants.dart';

/// Pro-лицензия: формат QS-PRO-XXXX и встроенные demo-ключи для тестирования.
class ProService {
  ProService._();
  static final ProService instance = ProService._();

  /// Публичные demo-ключи (beta / review builds).
  static const demoKeys = {'DEMO1', 'DEMO2026', 'REVIEW1'};

  bool validateLicenseKey(String key) {
    final trimmed = key.trim().toUpperCase();
    if (!trimmed.startsWith(AppConstants.proLicensePrefix)) return false;
    final suffix = trimmed.substring(AppConstants.proLicensePrefix.length);
    if (demoKeys.contains(suffix)) return true;
    return RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(suffix);
  }
}
