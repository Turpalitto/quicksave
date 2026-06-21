import 'package:share_plus/share_plus.dart';

import '../../features/history/domain/download_item.dart';
import '../../features/settings/domain/cloud_backup_config.dart';
import 'export/cloud/cloud_backup_adapter.dart';
import 'export/cloud/cloud_backup_registry.dart';
import 'export/cloud/cloud_backup_service.dart';
import 'export/export_service_base.dart';
import 'export/metadata_export_service.dart';
import 'export/zip_export_service.dart';

/// Facade for library export (ZIP, JSON, CSV) and optional cloud backup.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  final ZipExportService _zip = ZipExportService();
  final MetadataExportService _metadata = MetadataExportService();

  Future<String> exportToZip(List<DownloadItem> items) =>
      _zip.exportItems(items, format: ExportFormat.zip);

  Future<String> exportMetadataJson(List<DownloadItem> items) =>
      _metadata.exportItems(items, format: ExportFormat.json);

  Future<String> exportMetadataCsv(List<DownloadItem> items) =>
      _metadata.exportItems(items, format: ExportFormat.csv);

  Future<void> shareZip(List<DownloadItem> items) async {
    final zipPath = await exportToZip(items);
    await Share.shareXFiles([XFile(zipPath)], text: 'QuickSave export');
  }

  Future<void> shareMetadata(
    List<DownloadItem> items, {
    ExportFormat format = ExportFormat.json,
  }) async {
    final path = await _metadata.exportItems(items, format: format);
    await Share.shareXFiles([XFile(path)], text: 'QuickSave metadata');
  }

  /// Exports ZIP and optionally uploads to configured cloud destination.
  Future<CloudBackupResult?> exportZipWithOptionalCloudBackup(
    List<DownloadItem> items,
    CloudBackupConfig config, {
    bool shareAfterExport = true,
  }) async {
    final zipPath = await exportToZip(items);
    if (shareAfterExport) {
      await Share.shareXFiles([XFile(zipPath)], text: 'QuickSave export');
    }

    if (!config.enabled || !config.isConfigured) return null;
    return CloudBackupService.instance.uploadArchive(
      zipPath,
      config,
      remoteFileName: cloudBackupArchiveName(),
    );
  }

  Future<CloudBackupResult> backupZipToCloud(
    String zipPath,
    CloudBackupConfig config,
  ) => CloudBackupService.instance.uploadArchive(
    zipPath,
    config,
    remoteFileName: cloudBackupArchiveName(),
  );
}
