import 'package:package_info_plus/package_info_plus.dart';

/// Версия приложения из pubspec (package_info_plus).
class AppInfoService {
  AppInfoService._();
  static final AppInfoService instance = AppInfoService._();

  String _version = '1.0.0';
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
    } catch (_) {}
    _loaded = true;
  }

  String get version => _version;
}
