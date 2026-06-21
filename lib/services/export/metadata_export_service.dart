import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/history/domain/download_item.dart';
import 'export_service_base.dart';

/// JSON and CSV metadata export.
class MetadataExportService implements ExportServiceBase {
  @override
  Future<String> exportItems(
    List<DownloadItem> items, {
    ExportFormat format = ExportFormat.json,
  }) async {
    if (items.isEmpty) throw StateError('No items to export');

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;

    if (format == ExportFormat.csv) {
      final path = p.join(dir.path, 'quicksave_metadata_$stamp.csv');
      final buffer = StringBuffer(
        'id,sourceUrl,author,status,createdAt,filePath,shortcode\n',
      );
      for (final item in items) {
        buffer.writeln(
          [
            _csv(item.id),
            _csv(item.sourceUrl),
            _csv(item.author ?? ''),
            _csv(item.status.storageValue),
            _csv(item.createdAt.toIso8601String()),
            _csv(item.filePath),
            _csv(item.shortcode ?? item.provenance?.shortcode ?? ''),
          ].join(','),
        );
      }
      await File(path).writeAsString(buffer.toString());
      return path;
    }

    final path = p.join(dir.path, 'quicksave_metadata_$stamp.json');
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'itemCount': items.length,
      'attribution': exportAttributionNotice.trim(),
      'items': items.map((e) => e.toJson()).toList(),
    };
    await File(path).writeAsString(jsonEncode(payload));
    return path;
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
