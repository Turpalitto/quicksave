import 'package:flutter/foundation.dart';

/// Platform helpers for mobile vs web builds.
class PlatformSupport {
  PlatformSupport._();

  static bool get isWeb => kIsWeb;

  static bool get isMobileApp => !kIsWeb;
}
