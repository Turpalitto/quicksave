import 'package:workmanager/workmanager.dart';

import '../core/constants/app_constants.dart';
import '../features/settings/domain/app_settings.dart';

/// Планировщик проверки новых постов публичных профилей (Pro).
class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> syncFromSettings(AppSettings settings) async {
    try {
      await init();
      await Workmanager().cancelByUniqueName(AppConstants.schedulerTaskName);

      if (!settings.canUseScheduler) return;
      final enabled =
          settings.scheduledProfiles.where((p) => p.enabled).toList();
      if (enabled.isEmpty) return;

      await Workmanager().registerPeriodicTask(
        AppConstants.schedulerTaskName,
        AppConstants.schedulerTaskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        inputData: {
          'profiles': enabled.map((p) => p.profileUrl).toList(),
        },
      );
    } catch (_) {
      // Workmanager недоступен в unit/widget tests.
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Headless sync: уведомление пользователю открыть приложение для загрузки.
    // Полный headless download требует отдельного isolate с Dio + storage.
    return Future.value(true);
  });
}
