import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../features/history/domain/download_item.dart';
import '../features/history/domain/media_collection.dart';
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

  // ---------- History (v2 with v1 migration) ----------

  Future<List<DownloadItem>> loadHistory() async {
    final v2 = _p.getString(AppConstants.historyV2PrefsKey);
    if (v2 != null && v2.isNotEmpty) {
      return _decodeHistoryList(v2);
    }
    final v1 = _p.getString(AppConstants.historyPrefsKey);
    if (v1 == null || v1.isEmpty) return [];
    final migrated = _decodeHistoryList(v1);
    await saveHistory(migrated);
    await _p.remove(AppConstants.historyPrefsKey);
    return migrated;
  }

  List<DownloadItem> _decodeHistoryList(String raw) {
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
    await _p.setString(AppConstants.historyV2PrefsKey, encoded);
  }

  Future<void> clearHistory() async {
    await _p.remove(AppConstants.historyV2PrefsKey);
    await _p.remove(AppConstants.historyPrefsKey);
  }

  // ---------- Collections ----------

  Future<List<MediaCollection>> loadCollections() async {
    final raw = _p.getString(AppConstants.collectionsPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => MediaCollection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCollections(List<MediaCollection> collections) async {
    final encoded =
        jsonEncode(collections.map((e) => e.toJson()).toList());
    await _p.setString(AppConstants.collectionsPrefsKey, encoded);
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
