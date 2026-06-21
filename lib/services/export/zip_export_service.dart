import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/history/domain/download_item.dart';
import 'export_service_base.dart';

/// ZIP export with media files, metadata, README, and source URLs.
class ZipExportService implements ExportServiceBase {
  @override
  Future<String> exportItems(
    List<DownloadItem> items, {
    ExportFormat format = ExportFormat.zip,
  }) async {
    if (format != ExportFormat.zip) {
      throw UnsupportedError('ZipExportService supports zip only');
    }
    if (items.isEmpty) {
      throw StateError('No files to export');
    }

    final archive = Archive();
    final sourceUrls = <String>[];
    final metadata = <Map<String, dynamic>>[];

    for (final item in items) {
      sourceUrls.add(item.sourceUrl);
      metadata.add(item.toJson());
      final file = File(item.filePath);
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      final name = p.basename(item.filePath);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    archive.addFile(
      ArchiveFile(
        'metadata.json',
        utf8.encode(jsonEncode(metadata)).length,
        utf8.encode(jsonEncode(metadata)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'source_urls.txt',
        utf8.encode(sourceUrls.join('\n')).length,
        utf8.encode(sourceUrls.join('\n')),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'README.txt',
        utf8.encode(exportAttributionNotice).length,
        utf8.encode(exportAttributionNotice),
      ),
    );

    if (archive.files.length <= 3) {
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
}
