import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/scheduled_profile.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/scheduler_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repo) : super(const AppSettings()) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    final loaded = await _repo.get();
    state = loaded;
    await SchedulerService.instance.syncFromSettings(loaded);
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    await _repo.save(updated);
    await SchedulerService.instance.syncFromSettings(updated);
  }

  Future<void> setAutoDownload(bool v) =>
      update(state.copyWith(autoDownload: v));

  Future<void> setNotifications(bool v) =>
      update(state.copyWith(notificationsEnabled: v));

  Future<void> setSaveHistory(bool v) =>
      update(state.copyWith(saveHistory: v));

  Future<void> setWatchClipboard(bool v) =>
      update(state.copyWith(watchClipboard: v));

  Future<void> setSaveInAuthorFolder(bool v) =>
      update(state.copyWith(saveInAuthorFolder: v));

  Future<void> setSaveToGallery(bool v) =>
      update(state.copyWith(saveToGallery: v));

  Future<void> setOnboardingCompleted(bool v) =>
      update(state.copyWith(onboardingCompleted: v));

  Future<void> setBackendMode(BackendMode mode) =>
      update(state.copyWith(backendMode: mode));

  Future<void> setPro(bool v) => update(state.copyWith(isPro: v));

  Future<void> setThemeMode(AppThemeMode mode) =>
      update(state.copyWith(themeMode: mode));

  Future<void> setBackendUrl(String url) =>
      update(state.copyWith(backendUrl: url));

  Future<void> addScheduledProfile(String raw) async {
    if (!state.canUseScheduler) return;
    final url = Validators.prepareUrl(raw.trim());
    if (url == null) return;
    final username = url.split('/').where((s) => s.isNotEmpty).last;
    final profile = ScheduledProfile(
      username: username.replaceAll('@', ''),
      profileUrl: url,
    );
    final exists = state.scheduledProfiles.any((p) => p.username == profile.username);
    if (exists) return;
    await update(state.copyWith(
      scheduledProfiles: [...state.scheduledProfiles, profile],
    ));
  }

  Future<void> removeScheduledProfile(String username) async {
    await update(state.copyWith(
      scheduledProfiles: state.scheduledProfiles
          .where((p) => p.username != username)
          .toList(),
    ));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(SettingsRepository.instance),
);
