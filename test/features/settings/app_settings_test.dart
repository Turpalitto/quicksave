import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksave/core/constants/app_constants.dart';
import 'package:quicksave/features/settings/domain/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('defaults', () {
      const s = AppSettings();
      expect(s.autoDownload, true);
      expect(s.notificationsEnabled, true);
      expect(s.saveHistory, true);
      expect(s.saveToGallery, true);
      expect(s.watchClipboard, true);
      expect(s.themeMode, AppThemeMode.system);
      expect(s.backendMode, BackendMode.hosted);
      expect(s.backendUrl, AppConstants.defaultSelfHostedBackendUrl);
    });

    test('copyWith only changes specified fields', () {
      const s = AppSettings();
      final updated = s.copyWith(autoDownload: true, backendUrl: 'http://x');
      expect(updated.autoDownload, true);
      expect(updated.backendUrl, 'http://x');
      expect(updated.notificationsEnabled, s.notificationsEnabled);
      expect(updated.saveHistory, s.saveHistory);
      expect(updated.themeMode, s.themeMode);
    });

    test('toJson and fromJson roundtrip', () {
      const s = AppSettings(
        autoDownload: true,
        notificationsEnabled: false,
        saveHistory: true,
        themeMode: AppThemeMode.dark,
        backendUrl: 'http://api.test',
      );
      final json = s.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.autoDownload, s.autoDownload);
      expect(restored.notificationsEnabled, s.notificationsEnabled);
      expect(restored.saveHistory, s.saveHistory);
      expect(restored.themeMode, s.themeMode);
      expect(restored.backendUrl, s.backendUrl);
    });

    test('fromJson with empty map uses defaults', () {
      final s = AppSettings.fromJson({});
      expect(s.autoDownload, true);
      expect(s.notificationsEnabled, true);
    });

    test('fromJson ignores unknown themeMode', () {
      final s = AppSettings.fromJson({'themeMode': 'unknown'});
      expect(s.themeMode, AppThemeMode.system);
    });

    test('materialThemeMode conversion', () {
      expect(const AppSettings(themeMode: AppThemeMode.system).materialThemeMode,
          ThemeMode.system);
      expect(const AppSettings(themeMode: AppThemeMode.light).materialThemeMode,
          ThemeMode.light);
      expect(const AppSettings(themeMode: AppThemeMode.dark).materialThemeMode,
          ThemeMode.dark);
    });
  });
}
