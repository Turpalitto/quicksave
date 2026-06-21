import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/app_info_service.dart';
import 'services/intent_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация сервисов.
  await StorageService.instance.init();
  await AppInfoService.instance.init();
  await NotificationService.instance.init();
  IntentService.instance.initialize();

  runApp(
    const ProviderScope(
      child: QuickSaveApp(),
    ),
  );
}
