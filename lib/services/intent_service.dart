import 'dart:async';

import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';

/// Сервис для приёма текстовой ссылки из Android Share Intent.
/// Использует MethodChannel, который вызывается из MainActivity (Kotlin).
///
/// При cold-start (запуск из Share Intent) Kotlin вызывает
/// `onSharedText` ДО того, как Flutter успевает подписаться на стрим,
/// поэтому храним последний текст в [_pending] — подписчик заберёт его сам.
class IntentService {
  IntentService._();
  static final IntentService instance = IntentService._();

  static const MethodChannel _channel =
      MethodChannel(AppConstants.shareChannelName);

  final _controller = StreamController<String>.broadcast();
  Stream<String> get sharedTextStream => _controller.stream;

  String? _pending;
  bool _initialized = false;

  /// Инициализирует MethodChannel handler. Безопасно вызывать многократно.
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == AppConstants.shareChannelMethod) {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _pending = text;
          _controller.add(text);
        }
      }
    });
  }

  /// Возвращает последний pending-текст (cold-start) и очищает буфер.
  String? consumePending() {
    final t = _pending;
    _pending = null;
    return t;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
