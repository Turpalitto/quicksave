import 'dart:convert';

import '../../../core/constants/app_constants.dart';
import '../../../services/storage_service.dart';
import '../domain/pending_download.dart';

class PendingDownloadRepository {
  PendingDownloadRepository._();
  static final PendingDownloadRepository instance = PendingDownloadRepository._();

  Future<List<PendingDownload>> loadAll() async {
    final raw = StorageService.instance.prefs.getString(
      AppConstants.pendingDownloadsPrefsKey,
    );
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PendingDownload.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<PendingDownload> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await StorageService.instance.prefs.setString(
      AppConstants.pendingDownloadsPrefsKey,
      encoded,
    );
  }
}
