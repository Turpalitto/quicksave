import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quicksave/services/storage_service.dart';

/// Инициализация моков платформенных каналов для тестов.
Future<void> initPlatformMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences mock
  SharedPreferences.setMockInitialValues({});

  // StorageService кэширует SharedPreferences в синглтоне — инициализируем
  // ПОСЛЕ установки мока, иначе репозитории падают с
  // "StorageService.init() не вызван" в provider-тестах.
  await StorageService.instance.init();

  // MethodChannel mock для FlutterLocalNotifications
  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const notificationsCallbackChannel = MethodChannel(
      'dexterous.com/flutter/local_notifications/callbacks');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(notificationsChannel, (call) async {
    switch (call.method) {
      case 'initialize':
        return true;
      case 'show':
        return null;
      case 'cancel':
        return null;
      case 'requestNotificationsPermission':
        return true;
      default:
        return null;
    }
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(notificationsCallbackChannel, (call) async {
    return null;
  });

  // Path provider mock
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathChannel, (call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return '/tmp/test_docs';
    }
    if (call.method == 'getTemporaryDirectory') {
      return '/tmp/test_tmp';
    }
    if (call.method == 'getExternalStorageDirectory') {
      return '/tmp/test_ext';
    }
    return null;
  });
}
