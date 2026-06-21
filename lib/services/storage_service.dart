import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../features/history/domain/download_item.dart';
import '../features/settings/domain/app_settings.dart';

/// Сервис для сохранения истории и настроек через SharedPreferences.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('StorageService.init() не вызван');
    }
    return p;
  }

  // ---------- History ----------

  Future<List<DownloadItem>> loadHistory() async {
    final raw = _p.getString(AppConstants.historyPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<DownloadItem> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _p.setString(AppConstants.historyPrefsKey, encoded);
  }

  Future<void> clearHistory() async {
    await _p.remove(AppConstants.historyPrefsKey);
  }

  // ---------- Settings ----------

  Future<AppSettings> loadSettings() async {
    final raw = _p.getString(AppConstants.settingsPrefsKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _p.setString(
        AppConstants.settingsPrefsKey, jsonEncode(settings.toJson()));
  }

  Future<void> setJson(String key, Map<String, dynamic> json) async {
    await _p.setString(key, jsonEncode(json));
  }
}
