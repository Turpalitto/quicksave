import 'dart:io';

import 'package:path/path.dart' as p;

import '../../features/history/domain/download_item.dart';
import '../../services/download_service.dart';

/// Checks whether a local media path exists (filesystem paths only).
bool localMediaPathExists(String filePath) {
  if (filePath.isEmpty) return false;
  if (filePath.startsWith('content://')) return false;
  return File(filePath).existsSync();
}

/// Repairs history rows that stored a gallery [content://] URI instead of a file path.
Future<List<DownloadItem>> repairLegacyGalleryPaths(
  List<DownloadItem> items,
) async {
  if (!Platform.isAndroid) return items;

  final needsRepair = items.any((i) => i.filePath.startsWith('content://'));
  if (!needsRepair) return items;

  final dir = await DownloadService.instance.quickSaveDirectory();
  final onDisk = await dir
      .list()
      .where((e) => e is File)
      .cast<File>()
      .toList();

  var changed = false;
  final repaired = <DownloadItem>[];

  for (final item in items) {
    if (!item.filePath.startsWith('content://')) {
      repaired.add(item);
      continue;
    }

    final candidates = <String>{
      if (item.displayFileName != null && item.displayFileName!.isNotEmpty)
        p.join(dir.path, item.displayFileName!),
      if (item.shortcode != null && item.shortcode!.isNotEmpty)
        ...onDisk
            .where((f) => p.basename(f.path).contains(item.shortcode!))
            .map((f) => f.path),
    };

    String? resolved;
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        resolved = candidate;
        break;
      }
    }

    if (resolved != null) {
      repaired.add(item.copyWith(filePath: resolved));
      changed = true;
    } else {
      repaired.add(item);
    }
  }

  return changed ? repaired : items;
}
