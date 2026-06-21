import '../../features/history/domain/download_item.dart';

/// Export format options for media library backup.
enum ExportFormat { zip, json, csv }

/// Privacy-respecting export layer for saved public media.
abstract class ExportServiceBase {
  Future<String> exportItems(
    List<DownloadItem> items, {
    ExportFormat format = ExportFormat.zip,
  });
}

const exportAttributionNotice = '''
QuickSave Export
================
This archive contains public Instagram media you saved for personal use.
Respect creators and platform terms — do not repost without permission.
Source URLs are listed in source_urls.txt and metadata.json.
''';
