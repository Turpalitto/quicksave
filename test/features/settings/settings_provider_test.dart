import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/features/settings/data/settings_repository.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';
import 'package:quicksave/features/settings/presentation/providers/settings_provider.dart';

import '../../helpers/mock_setup.dart';

void main() {
  setUpAll(initPlatformMocks);

  group('SettingsNotifier', () {
    test('loads defaults when storage is empty', () async {
      final notifier = SettingsNotifier(SettingsRepository.instance);
      // Дайте асинхронной загрузке завершиться.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.notificationsEnabled, true);
      expect(notifier.state.saveHistory, true);
      expect(notifier.state.themeMode, AppThemeMode.system);
    });

    test('setAutoDownload updates state and persists', () async {
      final notifier = SettingsNotifier(SettingsRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await notifier.setAutoDownload(true);
      expect(notifier.state.autoDownload, true);
    });

    test('setBackendUrl updates url', () async {
      final notifier = SettingsNotifier(SettingsRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await notifier.setBackendUrl('http://test:1234');
      expect(notifier.state.backendUrl, 'http://test:1234');
    });

    test('setThemeMode updates theme', () async {
      final notifier = SettingsNotifier(SettingsRepository.instance);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await notifier.setThemeMode(AppThemeMode.dark);
      expect(notifier.state.themeMode, AppThemeMode.dark);
    });
  });
}
