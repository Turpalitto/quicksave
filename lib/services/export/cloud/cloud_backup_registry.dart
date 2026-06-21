import 'package:path/path.dart' as p;

import '../../../features/settings/domain/cloud_backup_config.dart';
import 'cloud_backup_adapter.dart';
import 'google_drive_backup_adapter.dart';
import 's3_backup_adapter.dart';
import 'webdav_backup_adapter.dart';

/// Resolves the active cloud backup adapter from user settings.
CloudBackupAdapter? cloudBackupAdapterFor(CloudBackupConfig config) {
  switch (config.provider) {
    case CloudBackupProvider.none:
      return null;
    case CloudBackupProvider.webdav:
      return WebDavBackupAdapter(config);
    case CloudBackupProvider.s3:
      return S3BackupAdapter(config);
    case CloudBackupProvider.googleDrive:
      return GoogleDriveBackupAdapter();
  }
}

/// Default remote archive name for library exports.
String cloudBackupArchiveName() {
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  return 'quicksave-export-$stamp.zip';
}

/// Extracts basename from a local export path.
String cloudBackupFileNameFromPath(String localPath) => p.basename(localPath);
