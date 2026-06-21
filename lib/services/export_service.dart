import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../features/history/domain/download_item.dart';

/// Экспорт batch-загрузок в ZIP.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<String> exportToZip(List<DownloadItem> items) async {
    if (items.isEmpty) {
      throw StateError('No files to export');
    }

    final archive = Archive();
    for (final item in items) {
      final file = File(item.filePath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final name = p.basename(item.filePath);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    if (archive.files.isEmpty) {
      throw StateError('Files missing on disk');
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = p.join(dir.path, 'quicksave_export_$stamp.zip');
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    for (final f in archive.files) {
      encoder.addArchiveFile(f);
    }
    encoder.close();
    return zipPath;
  }

  Future<void> shareZip(List<DownloadItem> items) async {
    final zipPath = await exportToZip(items);
    await Share.shareXFiles([XFile(zipPath)], text: 'QuickSave export');
  }
}
