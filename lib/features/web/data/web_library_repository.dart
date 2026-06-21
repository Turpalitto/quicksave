import 'dart:convert';

import '../../../services/storage_service.dart';

/// Browser-local library metadata imported from mobile exports (no file blobs).
class WebLibraryRepository {
  WebLibraryRepository._();
  static final WebLibraryRepository instance = WebLibraryRepository._();

  static const _prefsKey = 'quicksave.web.library.v1';

  Future<List<Map<String, dynamic>>> getAll() async {
    final raw = StorageService.instance.prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    await StorageService.instance.prefs.setString(_prefsKey, jsonEncode(items));
  }

  Future<int> importFromJsonString(String raw) async {
    final parsed = jsonDecode(raw);
    final incoming = _extractItems(parsed);
    if (incoming.isEmpty) return 0;

    final existing = await getAll();
    final byId = {for (final e in existing) e['id'] as String: e};
    for (final item in incoming) {
      final id = item['id'] as String?;
      if (id == null || id.isEmpty) continue;
      byId[id] = item;
    }
    final merged = byId.values.toList()
      ..sort(
        (a, b) => (b['createdAt'] as String? ?? '').compareTo(
          a['createdAt'] as String? ?? '',
        ),
      );
    await saveAll(merged);
    return incoming.length;
  }

  Future<void> clear() async {
    await StorageService.instance.prefs.remove(_prefsKey);
  }

  List<Map<String, dynamic>> _extractItems(dynamic parsed) {
    if (parsed is List) {
      return parsed.whereType<Map<String, dynamic>>().toList();
    }
    if (parsed is Map<String, dynamic>) {
      final items = parsed['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  String toCsv(List<Map<String, dynamic>> items) {
    const header = 'id,sourceUrl,author,mediaType,status,createdAt,caption';
    final rows = items.map((item) {
      String esc(String? v) {
        final s = (v ?? '').replaceAll('"', '""');
        return '"$s"';
      }

      return [
        esc(item['id'] as String?),
        esc(item['sourceUrl'] as String?),
        esc(item['author'] as String?),
        esc(item['mediaType'] as String?),
        esc(item['status'] as String?),
        esc(item['createdAt'] as String?),
        esc(item['caption'] as String?),
      ].join(',');
    });
    return '$header\n${rows.join('\n')}';
  }
}
