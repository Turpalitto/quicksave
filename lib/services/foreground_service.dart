import 'dart:io';

import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';

/// Тонкая обёртка над Kotlin foreground-сервисом скачивания.
///
/// На Android держит процесс живым во время длительной загрузки,
/// показывая ongoing-уведомление с процентом. На других платформах — no-op.
///
/// Все методы проглатывают платформенные ошибки: foreground-сервис —
/// это улучшение UX, а не обязательная часть потока скачивания.
/// Если он не запустится (например, нет разрешения), загрузка всё равно
/// продолжится в обычном режиме.
class ForegroundService {
  ForegroundService._();
  static final ForegroundService instance = ForegroundService._();

  static const MethodChannel _channel =
      MethodChannel(AppConstants.foregroundChannelName);

  bool _running = false;

  /// Запускает foreground-сервис с начальным прогрессом 0%.
  Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (_running) return;
    try {
      await _channel.invokeMethod('start');
      _running = true;
    } on PlatformException catch (_) {
      // Сервис не смог стартовать (ограничения Android 14 / нет разрешения) —
      // не блокируем скачивание.
    } on MissingPluginException catch (_) {
      // Канал ещё не зарегистрирован (например, в тестах) — игнорируем.
    } catch (_) {
      // Любая другая ошибка платформы — не роняем загрузку.
    }
  }

  /// Обновляет процент в уведомлении. [progress] в диапазоне 0.0–1.0.
  Future<void> updateProgress(double progress) async {
    if (!Platform.isAndroid || !_running) return;
    try {
      final percent = (progress.clamp(0.0, 1.0) * 100).round();
      await _channel.invokeMethod('progress', {'percent': percent});
    } catch (_) {
      // обновление прогресса не критично
    }
  }

  /// Останавливает foreground-сервис и убирает уведомление.
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!_running) return;
    _running = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {
      // сервис уже мог остановиться — игнорируем
    }
  }
}
