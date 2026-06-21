import 'package:workmanager/workmanager.dart';

import '../core/constants/app_constants.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/domain/scheduled_profile.dart';
import '../features/settings/domain/scheduler_frequency.dart';

/// Планировщик проверки новых постов публичных профилей (Pro).
/// Headless auto-download is intentionally limited — user must open app.
class SchedulerService {
  SchedulerService._();
  static final SchedulerService instance = SchedulerService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await Workmanager().initialize(callbackDispatcher);
  }

  Duration? _minFrequency(List<ScheduledProfile> profiles) {
    Duration? min;
    for (final p in profiles) {
      if (!p.enabled || p.frequency == SchedulerFrequency.manual) continue;
      final err = SchedulerFrequencyValidator.validate(p.frequency);
      if (err != null) continue;
      final d = p.frequency.interval;
      if (d == null) continue;
      if (min == null || d > min) min = d;
    }
    return min;
  }

  NetworkType _networkType(List<ScheduledProfile> profiles) {
    if (profiles.any((p) => p.enabled && p.wifiOnly)) {
      return NetworkType.unmetered;
    }
    return NetworkType.connected;
  }

  bool _requiresCharging(List<ScheduledProfile> profiles) =>
      profiles.any((p) => p.enabled && p.chargingOnly);

  Future<void> syncFromSettings(AppSettings settings) async {
    try {
      await init();
      await Workmanager().cancelByUniqueName(AppConstants.schedulerTaskName);

      if (!settings.canUseScheduler) return;
      final enabled = settings.scheduledProfiles
          .where((p) => p.enabled)
          .toList();
      if (enabled.isEmpty) return;

      final frequency = _minFrequency(enabled) ?? const Duration(hours: 24);
      if (frequency.inHours < 12) return;

      await Workmanager().registerPeriodicTask(
        AppConstants.schedulerTaskName,
        AppConstants.schedulerTaskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: _networkType(enabled),
          requiresCharging: _requiresCharging(enabled),
        ),
        inputData: {
          'profiles': enabled.map((p) => p.profileUrl).toList(),
          'autoSave': enabled.any((p) => p.autoSaveNewPosts),
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
    // Scaffold: notify user to open app for manual sync.
    // Full headless download requires isolate + user consent (see docs/ROADMAP.md).
    return Future.value(true);
  });
}
