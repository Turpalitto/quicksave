import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/app_info_service.dart';
import 'services/entitlement_service.dart';
import 'services/intent_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.instance.init();
  await AppInfoService.instance.init();

  if (kIsWeb) {
    await EntitlementService.instance.refresh();
  } else {
    await NotificationService.instance.init();
    IntentService.instance.initialize();
    await EntitlementService.instance.bootstrap();
  }

  runApp(const ProviderScope(child: QuickSaveApp()));
}
