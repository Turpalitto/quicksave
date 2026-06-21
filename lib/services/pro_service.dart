import '../core/constants/app_constants.dart';

/// Pro license validation and tier hints.
class ProService {
  ProService._();
  static final ProService instance = ProService._();

  /// Public demo keys (beta / review builds).
  static const demoKeys = {'DEMO1', 'DEMO2026', 'REVIEW1'};

  bool validateLicenseKey(String key) {
    final trimmed = key.trim().toUpperCase();
    if (!trimmed.startsWith(AppConstants.proLicensePrefix)) return false;
    final suffix = suffixOf(trimmed);
    if (demoKeys.contains(suffix)) return true;
    if (isSelfHostedKey(trimmed)) {
      return RegExp(r'^SHOST[A-Z0-9]{4,10}$').hasMatch(suffix);
    }
    return RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(suffix);
  }

  bool isDemoKey(String key) {
    final suffix = suffixOf(key.trim().toUpperCase());
    return demoKeys.contains(suffix);
  }

  bool isSelfHostedKey(String key) {
    final suffix = suffixOf(key.trim().toUpperCase());
    return suffix.startsWith('SHOST');
  }

  String suffixOf(String normalizedKey) {
    if (!normalizedKey.startsWith(AppConstants.proLicensePrefix)) return '';
    return normalizedKey.substring(AppConstants.proLicensePrefix.length);
  }

  /// Last 4 chars for display — never store full key in analytics/logs.
  String licenseHint(String key) {
    final trimmed = key.trim().toUpperCase();
    if (trimmed.length <= 4) return '****';
    return trimmed.substring(trimmed.length - 4);
  }
}
