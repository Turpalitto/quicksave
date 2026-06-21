import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Сервис локальных уведомлений.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _plugin.initialize(initSettings);

      if (Platform.isAndroid) {
        try {
          await Permission.notification.request();
        } catch (e) {
          debugPrint('Notification permission error: $e');
        }

        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        try {
          await android?.requestNotificationsPermission();
        } catch (e) {
          debugPrint('Notifications permission request error: $e');
        }
      }
    } catch (e) {
      debugPrint('NotificationService.init skipped: $e');
    }

    _ready = true;
  }

  Future<void> showDownloadComplete({
    required String title,
    required String body,
    String? payload,
    String channelName = 'Downloads',
    String channelDescription = 'Download notifications',
  }) async {
    if (!_ready) await init();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'downloads',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showDownloadError(
    String message, {
    String title = 'Download error',
    String channelName = 'Downloads',
    String channelDescription = 'Download notifications',
  }) async {
    if (!_ready) await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
